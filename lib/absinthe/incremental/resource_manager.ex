defmodule Absinthe.Incremental.ResourceManager do
  @moduledoc """
  Manages resources for streaming operations.

  This GenServer tracks and limits concurrent streaming operations,
  monitors memory usage, and ensures proper cleanup of resources.
  """

  use GenServer
  require Logger

  @default_config %{
    max_concurrent_streams: 100,
    # 30 seconds
    max_stream_duration: 30_000,
    max_memory_mb: 500,
    # Check resources every 5 seconds
    check_interval: 5_000
  }

  defstruct [
    :config,
    :active_streams,
    :stream_stats,
    :memory_baseline
  ]

  @type stream_info :: %{
          operation_id: String.t(),
          started_at: integer(),
          memory_baseline: integer(),
          pid: pid() | nil,
          label: String.t() | nil,
          path: list()
        }

  # Client API

  @doc """
  Start the resource manager.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Acquire a slot for a new streaming operation.

  Returns :ok if resources are available, or an error if limits are exceeded.
  """
  @spec acquire_stream_slot(String.t(), Keyword.t()) :: :ok | {:error, term()}
  def acquire_stream_slot(operation_id, opts \\ []) do
    GenServer.call(__MODULE__, {:acquire, operation_id, opts})
  end

  @doc """
  Release a streaming slot when operation completes.
  """
  @spec release_stream_slot(String.t()) :: :ok
  def release_stream_slot(operation_id) do
    GenServer.cast(__MODULE__, {:release, operation_id})
  end

  @doc """
  Get current resource usage statistics.
  """
  @spec get_stats() :: map()
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @doc """
  Check if a streaming operation is still active.
  """
  @spec stream_active?(String.t()) :: boolean()
  def stream_active?(operation_id) do
    GenServer.call(__MODULE__, {:check_active, operation_id})
  end

  @doc """
  Update configuration at runtime.
  """
  @spec update_config(map()) :: :ok
  def update_config(config) do
    GenServer.call(__MODULE__, {:update_config, config})
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    config =
      @default_config
      |> Map.merge(Enum.into(opts, %{}))

    # Schedule periodic resource checks
    schedule_resource_check(config.check_interval)

    {:ok,
     %__MODULE__{
       config: config,
       active_streams: %{},
       stream_stats: init_stats(),
       memory_baseline: :erlang.memory(:total)
     }}
  end

  @impl true
  def handle_call({:acquire, operation_id, opts}, _from, state) do
    cond do
      # Check if we already have this operation
      Map.has_key?(state.active_streams, operation_id) ->
        {:reply, {:error, :duplicate_operation}, state}

      # Check concurrent stream limit
      map_size(state.active_streams) >= state.config.max_concurrent_streams ->
        {:reply, {:error, :max_concurrent_streams}, state}

      # Check memory limit
      exceeds_memory_limit?(state) ->
        {:reply, {:error, :memory_limit_exceeded}, state}

      true ->
        # Acquire the slot
        stream_info = %{
          operation_id: operation_id,
          started_at: System.monotonic_time(:millisecond),
          memory_baseline: :erlang.memory(:total),
          pid: Keyword.get(opts, :pid),
          label: Keyword.get(opts, :label),
          path: Keyword.get(opts, :path, [])
        }

        new_state =
          state
          |> put_in([:active_streams, operation_id], stream_info)
          |> update_stats(:stream_acquired)

        # Schedule timeout for this stream
        schedule_stream_timeout(operation_id, state.config.max_stream_duration)

        Logger.debug("Acquired stream slot for operation #{operation_id}")

        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:check_active, operation_id}, _from, state) do
    {:reply, Map.has_key?(state.active_streams, operation_id), state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      active_streams: map_size(state.active_streams),
      total_streams: state.stream_stats.total_count,
      failed_streams: state.stream_stats.failed_count,
      memory_usage_mb: :erlang.memory(:total) / 1_048_576,
      avg_stream_duration_ms: calculate_avg_duration(state.stream_stats),
      config: state.config
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_call({:update_config, new_config}, _from, state) do
    updated_config = Map.merge(state.config, new_config)
    {:reply, :ok, %{state | config: updated_config}}
  end

  @impl true
  def handle_cast({:release, operation_id}, state) do
    case Map.get(state.active_streams, operation_id) do
      nil ->
        {:noreply, state}

      stream_info ->
        duration = System.monotonic_time(:millisecond) - stream_info.started_at

        new_state =
          state
          |> update_in([:active_streams], &Map.delete(&1, operation_id))
          |> update_stats(:stream_released, duration)

        Logger.debug(
          "Released stream slot for operation #{operation_id} (duration: #{duration}ms)"
        )

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_info({:stream_timeout, operation_id}, state) do
    case Map.get(state.active_streams, operation_id) do
      nil ->
        # Already released
        {:noreply, state}

      stream_info ->
        Logger.warning("Stream timeout for operation #{operation_id}")

        # Kill the associated process if it exists
        if stream_info.pid && Process.alive?(stream_info.pid) do
          Process.exit(stream_info.pid, :timeout)
        end

        # Release the stream
        new_state =
          state
          |> update_in([:active_streams], &Map.delete(&1, operation_id))
          |> update_stats(:stream_timeout)

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_info(:check_resources, state) do
    # Periodic resource check
    state =
      state
      |> check_memory_pressure()
      |> check_stale_streams()

    # Schedule next check
    schedule_resource_check(state.config.check_interval)

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    # Handle process crashes
    case find_stream_by_pid(state.active_streams, pid) do
      nil ->
        {:noreply, state}

      {operation_id, _stream_info} ->
        Logger.warning("Stream process crashed for operation #{operation_id}: #{inspect(reason)}")

        new_state =
          state
          |> update_in([:active_streams], &Map.delete(&1, operation_id))
          |> update_stats(:stream_crashed)

        {:noreply, new_state}
    end
  end

  # Private functions

  defp init_stats do
    %{
      total_count: 0,
      completed_count: 0,
      failed_count: 0,
      timeout_count: 0,
      total_duration: 0,
      max_duration: 0,
      min_duration: nil
    }
  end

  defp update_stats(state, :stream_acquired) do
    update_in(state.stream_stats.total_count, &(&1 + 1))
  end

  defp update_stats(state, :stream_released, duration) do
    state
    |> update_in([:stream_stats, :completed_count], &(&1 + 1))
    |> update_in([:stream_stats, :total_duration], &(&1 + duration))
    |> update_in([:stream_stats, :max_duration], &max(&1, duration))
    |> update_in([:stream_stats, :min_duration], fn
      nil -> duration
      min -> min(min, duration)
    end)
  end

  defp update_stats(state, :stream_timeout) do
    state
    |> update_in([:stream_stats, :timeout_count], &(&1 + 1))
    |> update_in([:stream_stats, :failed_count], &(&1 + 1))
  end

  defp update_stats(state, :stream_crashed) do
    update_in(state.stream_stats.failed_count, &(&1 + 1))
  end

  defp exceeds_memory_limit?(state) do
    current_memory_mb = :erlang.memory(:total) / 1_048_576
    current_memory_mb > state.config.max_memory_mb
  end

  defp schedule_stream_timeout(operation_id, timeout_ms) do
    Process.send_after(self(), {:stream_timeout, operation_id}, timeout_ms)
  end

  defp schedule_resource_check(interval_ms) do
    Process.send_after(self(), :check_resources, interval_ms)
  end

  defp check_memory_pressure(state) do
    if exceeds_memory_limit?(state) do
      Logger.warning("Memory pressure detected, may reject new streams")

      # Could implement more aggressive cleanup here
      # For now, just log the warning
    end

    state
  end

  defp check_stale_streams(state) do
    now = System.monotonic_time(:millisecond)
    max_duration = state.config.max_stream_duration

    stale_streams =
      state.active_streams
      |> Enum.filter(fn {_id, info} ->
        # 2x timeout = definitely stale
        now - info.started_at > max_duration * 2
      end)

    if not Enum.empty?(stale_streams) do
      Logger.warning("Found #{length(stale_streams)} stale streams, cleaning up")

      Enum.reduce(stale_streams, state, fn {operation_id, _info}, acc ->
        update_in(acc.active_streams, &Map.delete(&1, operation_id))
      end)
    else
      state
    end
  end

  defp find_stream_by_pid(active_streams, pid) do
    Enum.find(active_streams, fn {_id, info} ->
      info.pid == pid
    end)
  end

  defp calculate_avg_duration(%{completed_count: 0}), do: 0

  defp calculate_avg_duration(stats) do
    div(stats.total_duration, stats.completed_count)
  end
end
