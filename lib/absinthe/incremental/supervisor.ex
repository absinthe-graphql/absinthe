defmodule Absinthe.Incremental.Supervisor do
  @moduledoc """
  Supervisor for incremental delivery components.

  This supervisor manages the resource manager and task supervisors
  needed for @defer and @stream operations.

  ## Starting the Supervisor

  To enable incremental delivery, add this supervisor to your application's
  supervision tree in `application.ex`:

      defmodule MyApp.Application do
        use Application

        def start(_type, _args) do
          children = [
            # ... other children
            {Absinthe.Incremental.Supervisor, [
              enabled: true,
              enable_defer: true,
              enable_stream: true,
              max_concurrent_defers: 10,
              max_concurrent_streams: 5
            ]}
          ]

          opts = [strategy: :one_for_one, name: MyApp.Supervisor]
          Supervisor.start_link(children, opts)
        end
      end

  ## Configuration Options

  - `:enabled` - Enable/disable incremental delivery (default: false)
  - `:enable_defer` - Enable @defer directive support (default: true when enabled)
  - `:enable_stream` - Enable @stream directive support (default: true when enabled)
  - `:max_concurrent_defers` - Max concurrent deferred operations (default: 100)
  - `:max_concurrent_streams` - Max concurrent stream operations (default: 50)

  ## Note

  The supervisor is only required for actual incremental delivery over transports
  (SSE, WebSocket). Standard query execution with @defer/@stream directives will
  work without the supervisor, but will return all data in a single response.
  """

  use Supervisor

  @doc """
  Start the incremental delivery supervisor.
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    config = Absinthe.Incremental.Config.from_options(opts)

    children =
      if config.enabled do
        [
          # Resource manager for tracking and limiting concurrent operations
          {Absinthe.Incremental.ResourceManager, Map.to_list(config)},

          # Task supervisor for deferred operations
          {Task.Supervisor, name: Absinthe.Incremental.DeferredTaskSupervisor},

          # Task supervisor for streamed operations
          {Task.Supervisor, name: Absinthe.Incremental.StreamTaskSupervisor},

          # Telemetry reporter if enabled
          telemetry_reporter(config)
        ]
        |> Enum.filter(& &1)
      else
        []
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Check if the supervisor is running.
  """
  @spec running?() :: boolean()
  def running? do
    case Process.whereis(__MODULE__) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  end

  @doc """
  Restart the supervisor with new configuration.
  """
  @spec restart(Keyword.t()) :: {:ok, pid()} | {:error, term()}
  def restart(opts \\ []) do
    if running?() do
      Supervisor.stop(__MODULE__)
    end

    start_link(opts)
  end

  @doc """
  Get the current configuration.
  """
  @spec get_config() :: Absinthe.Incremental.Config.t() | nil
  def get_config do
    if running?() do
      # Get config from resource manager
      stats = Absinthe.Incremental.ResourceManager.get_stats()
      Map.get(stats, :config)
    end
  end

  @doc """
  Update configuration at runtime.
  """
  @spec update_config(map()) :: :ok | {:error, :not_running}
  def update_config(config) do
    if running?() do
      Absinthe.Incremental.ResourceManager.update_config(config)
    else
      {:error, :not_running}
    end
  end

  @doc """
  Start a deferred task under supervision.
  """
  @spec start_deferred_task((-> any())) :: {:ok, pid()} | {:error, term()}
  def start_deferred_task(fun) do
    if running?() do
      Task.Supervisor.async_nolink(
        Absinthe.Incremental.DeferredTaskSupervisor,
        fun
      )
      |> Map.get(:pid)
      |> then(&{:ok, &1})
    else
      {:error, :supervisor_not_running}
    end
  end

  @doc """
  Start a streaming task under supervision.
  """
  @spec start_stream_task((-> any())) :: {:ok, pid()} | {:error, term()}
  def start_stream_task(fun) do
    if running?() do
      Task.Supervisor.async_nolink(
        Absinthe.Incremental.StreamTaskSupervisor,
        fun
      )
      |> Map.get(:pid)
      |> then(&{:ok, &1})
    else
      {:error, :supervisor_not_running}
    end
  end

  @doc """
  Get statistics about current operations.
  """
  @spec get_stats() :: map() | {:error, :not_running}
  def get_stats do
    if running?() do
      resource_stats = Absinthe.Incremental.ResourceManager.get_stats()

      deferred_tasks =
        Task.Supervisor.children(Absinthe.Incremental.DeferredTaskSupervisor)
        |> length()

      stream_tasks =
        Task.Supervisor.children(Absinthe.Incremental.StreamTaskSupervisor)
        |> length()

      Map.merge(resource_stats, %{
        active_deferred_tasks: deferred_tasks,
        active_stream_tasks: stream_tasks,
        total_active_tasks: deferred_tasks + stream_tasks
      })
    else
      {:error, :not_running}
    end
  end

  # Private functions

  defp telemetry_reporter(%{enable_telemetry: true}) do
    {Absinthe.Incremental.TelemetryReporter, []}
  end

  defp telemetry_reporter(_), do: nil
end
