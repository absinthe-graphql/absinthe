defmodule Absinthe.Streaming.TaskExecutor do
  @moduledoc """
  Default executor using `Task.async_stream` for concurrent task execution.

  This is the default implementation of `Absinthe.Streaming.Executor` behaviour.
  It uses Elixir's built-in `Task.async_stream` for concurrent execution with
  configurable timeouts and concurrency limits.

  ## Features

  - Concurrent execution with configurable concurrency limits
  - Timeout handling per task
  - Error wrapping and recovery
  - Streaming results (lazy evaluation)

  ## Usage

      tasks = Absinthe.Streaming.get_streaming_tasks(blueprint)

      # Stream results (lazy evaluation)
      tasks
      |> TaskExecutor.execute_stream(timeout: 30_000)
      |> Enum.each(fn result -> ... end)

      # Or collect all at once
      results = TaskExecutor.execute_all(tasks, timeout: 30_000)

  ## Custom Executors

  To use a different execution backend (Oban, RabbitMQ, etc.), implement the
  `Absinthe.Streaming.Executor` behaviour and configure it in your schema:

      defmodule MyApp.Schema do
        use Absinthe.Schema

        @streaming_executor MyApp.ObanExecutor

        # ... schema definition
      end

  See `Absinthe.Streaming.Executor` for details on implementing custom executors.
  """

  @behaviour Absinthe.Streaming.Executor

  alias Absinthe.Incremental.ErrorHandler

  @default_timeout 30_000
  @default_max_concurrency System.schedulers_online() * 2

  @type task :: %{
          id: String.t(),
          type: :defer | :stream,
          label: String.t() | nil,
          path: list(String.t()),
          execute: (-> {:ok, map()} | {:error, term()})
        }

  @type task_result :: %{
          task: task(),
          result: {:ok, map()} | {:error, term()},
          duration_ms: non_neg_integer(),
          has_next: boolean(),
          success: boolean()
        }

  @type execute_option ::
          {:timeout, non_neg_integer()}
          | {:max_concurrency, pos_integer()}

  # ============================================================================
  # Executor Behaviour Implementation
  # ============================================================================

  @doc """
  Execute tasks and return results as an enumerable.

  This is the main `Absinthe.Streaming.Executor` callback implementation.
  It uses `Task.async_stream` for concurrent execution with backpressure.

  ## Options

  - `:timeout` - Maximum time to wait for each task (default: #{@default_timeout}ms)
  - `:max_concurrency` - Maximum concurrent tasks (default: #{@default_max_concurrency})

  ## Returns

  A `Stream` that yields result maps as tasks complete.
  """
  @impl Absinthe.Streaming.Executor
  def execute(tasks, opts \\ []) do
    execute_stream(tasks, opts)
  end

  # ============================================================================
  # Convenience Functions
  # ============================================================================

  @doc """
  Execute tasks and return results as a stream.

  Results are yielded as they complete, allowing for streaming delivery
  without waiting for all tasks to finish.

  ## Options

  - `:timeout` - Maximum time to wait for each task (default: #{@default_timeout}ms)
  - `:max_concurrency` - Maximum concurrent tasks (default: #{@default_max_concurrency})

  ## Returns

  A `Stream` that yields `task_result()` maps.
  """
  @spec execute_stream(list(task()), [execute_option()]) :: Enumerable.t()
  def execute_stream(tasks, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    max_concurrency = Keyword.get(opts, :max_concurrency, @default_max_concurrency)
    task_count = length(tasks)

    tasks
    |> Task.async_stream(
      fn task ->
        task_started = System.monotonic_time(:millisecond)
        wrapped_fn = ErrorHandler.wrap_streaming_task(task.execute)
        result = wrapped_fn.()
        duration_ms = System.monotonic_time(:millisecond) - task_started
        {task, result, duration_ms}
      end,
      timeout: timeout,
      on_timeout: :kill_task,
      max_concurrency: max_concurrency
    )
    |> Stream.with_index()
    |> Stream.map(fn {stream_result, index} ->
      has_next = index < task_count - 1
      format_stream_result(stream_result, has_next)
    end)
  end

  @doc """
  Execute all tasks and collect results.

  This is a convenience function that executes `execute_stream/2` and
  collects all results into a list.

  ## Options

  Same as `execute_stream/2`.

  ## Returns

  A list of `task_result()` maps.
  """
  @spec execute_all(list(task()), [execute_option()]) :: [task_result()]
  def execute_all(tasks, opts \\ []) do
    tasks
    |> execute_stream(opts)
    |> Enum.to_list()
  end

  @doc """
  Execute a single task with error handling.

  ## Options

  - `:timeout` - Maximum time to wait (default: #{@default_timeout}ms)

  ## Returns

  A `task_result()` map.
  """
  @spec execute_one(task(), [execute_option()]) :: task_result()
  def execute_one(task, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    task_ref =
      Task.async(fn ->
        task_started = System.monotonic_time(:millisecond)
        wrapped_fn = ErrorHandler.wrap_streaming_task(task.execute)
        result = wrapped_fn.()
        duration_ms = System.monotonic_time(:millisecond) - task_started
        {task, result, duration_ms}
      end)

    case Task.yield(task_ref, timeout) || Task.shutdown(task_ref) do
      {:ok, {task, result, duration_ms}} ->
        %{
          task: task,
          result: result,
          duration_ms: duration_ms,
          has_next: false,
          success: match?({:ok, _}, result)
        }

      nil ->
        %{
          task: task,
          result: {:error, :timeout},
          duration_ms: timeout,
          has_next: false,
          success: false
        }
    end
  end

  # Format the result from Task.async_stream
  defp format_stream_result({:ok, {task, result, duration_ms}}, has_next) do
    %{
      task: task,
      result: result,
      duration_ms: duration_ms,
      has_next: has_next,
      success: match?({:ok, _}, result)
    }
  end

  defp format_stream_result({:exit, :timeout}, has_next) do
    %{
      task: nil,
      result: {:error, :timeout},
      duration_ms: 0,
      has_next: has_next,
      success: false
    }
  end

  defp format_stream_result({:exit, reason}, has_next) do
    %{
      task: nil,
      result: {:error, {:exit, reason}},
      duration_ms: 0,
      has_next: has_next,
      success: false
    }
  end
end
