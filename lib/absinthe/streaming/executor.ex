defmodule Absinthe.Streaming.Executor do
  @moduledoc """
  Behaviour for pluggable task execution backends.

  The default executor uses `Task.async_stream` for in-process concurrent execution.
  You can implement this behaviour to use alternative backends like:

  - **Oban** - For persistent, retryable job processing
  - **RabbitMQ** - For distributed task queuing
  - **GenStage** - For backpressure-aware pipelines
  - **Custom** - Any execution strategy you need

  ## Implementing a Custom Executor

  Implement the `execute/2` callback to process tasks and return results:

      defmodule MyApp.ObanExecutor do
        @behaviour Absinthe.Streaming.Executor

        @impl true
        def execute(tasks, opts) do
          # Queue tasks to Oban and return results as they complete
          timeout = Keyword.get(opts, :timeout, 30_000)

          tasks
          |> Enum.map(&queue_to_oban/1)
          |> wait_for_results(timeout)
        end

        defp queue_to_oban(task) do
          # Insert Oban job and track it
          {:ok, job} = Oban.insert(MyApp.DeferredWorker.new(%{task_id: task.id}))
          {task, job}
        end

        defp wait_for_results(jobs, timeout) do
          # Stream results as jobs complete
          Stream.resource(
            fn -> {jobs, timeout} end,
            &poll_next_result/1,
            fn _ -> :ok end
          )
        end
      end

  ## Configuration

  Configure the executor at different levels:

  ### Schema-level (recommended for schema-wide settings)

      defmodule MyApp.Schema do
        use Absinthe.Schema

        @streaming_executor MyApp.ObanExecutor

        # ... schema definition
      end

  ### Runtime (per-request)

      Absinthe.run(query, MyApp.Schema,
        context: %{streaming_executor: MyApp.ObanExecutor}
      )

  ### Application config (global default)

      config :absinthe, :streaming_executor, MyApp.ObanExecutor

  ## Result Format

  Your executor must return an enumerable (list or stream) of result maps:

      %{
        task: task,           # The original task map
        result: {:ok, data} | {:error, reason},
        has_next: boolean,    # true if more results coming
        success: boolean,     # true if result is {:ok, _}
        duration_ms: integer  # execution time in milliseconds
      }

  """

  @type task :: %{
          required(:id) => String.t(),
          required(:type) => :defer | :stream,
          required(:path) => [String.t() | integer()],
          required(:execute) => (-> {:ok, map()} | {:error, term()}),
          optional(:label) => String.t() | nil
        }

  @type result :: %{
          task: task(),
          result: {:ok, map()} | {:error, term()},
          has_next: boolean(),
          success: boolean(),
          duration_ms: non_neg_integer()
        }

  @type option ::
          {:timeout, non_neg_integer()}
          | {:max_concurrency, pos_integer()}

  @doc """
  Execute a list of deferred/streamed tasks and return results.

  This callback receives a list of tasks and must return an enumerable
  of results. The results can be returned as:

  - A list (all results computed eagerly)
  - A Stream (results yielded as they complete)

  ## Parameters

  - `tasks` - List of task maps with `:id`, `:type`, `:path`, `:execute`, and optional `:label`
  - `opts` - Keyword list of options:
    - `:timeout` - Maximum time per task (default: 30_000ms)
    - `:max_concurrency` - Maximum concurrent tasks (default: CPU count * 2)

  ## Return Value

  Must return an enumerable of result maps. Each result must include:

  - `:task` - The original task map
  - `:result` - `{:ok, data}` or `{:error, reason}`
  - `:has_next` - `true` if more results are coming, `false` for the last result
  - `:success` - `true` if result is `{:ok, _}`, `false` otherwise
  - `:duration_ms` - Execution time in milliseconds

  ## Example

      def execute(tasks, opts) do
        timeout = Keyword.get(opts, :timeout, 30_000)
        task_count = length(tasks)

        tasks
        |> Enum.with_index()
        |> Enum.map(fn {task, index} ->
          started = System.monotonic_time(:millisecond)
          result = safe_execute(task.execute, timeout)
          duration = System.monotonic_time(:millisecond) - started

          %{
            task: task,
            result: result,
            has_next: index < task_count - 1,
            success: match?({:ok, _}, result),
            duration_ms: duration
          }
        end)
      end
  """
  @callback execute(tasks :: [task()], opts :: [option()]) :: Enumerable.t(result())

  @doc """
  Optional callback for cleanup when execution is cancelled.

  Implement this if your executor needs to clean up resources (e.g., cancel
  queued jobs, close connections) when a subscription is unsubscribed or
  a request is cancelled.

  The default implementation is a no-op.
  """
  @callback cancel(reference :: term()) :: :ok

  @optional_callbacks [cancel: 1]

  @doc """
  Get the configured executor module.

  Checks in order:
  1. Explicit executor passed in opts
  2. Schema-level `@streaming_executor` attribute
  3. Application config `:absinthe, :streaming_executor`
  4. Default `Absinthe.Streaming.TaskExecutor`
  """
  @spec get_executor(schema :: module() | nil, opts :: keyword()) :: module()
  def get_executor(schema \\ nil, opts \\ []) do
    cond do
      # 1. Explicit option
      executor = Keyword.get(opts, :executor) ->
        executor

      # 2. Context option (for runtime config)
      executor = get_in(opts, [:context, :streaming_executor]) ->
        executor

      # 3. Schema-level attribute
      schema && function_exported?(schema, :__absinthe_streaming_executor__, 0) ->
        schema.__absinthe_streaming_executor__()

      # 4. Application config
      executor = Application.get_env(:absinthe, :streaming_executor) ->
        executor

      # 5. Default
      true ->
        Absinthe.Streaming.TaskExecutor
    end
  end
end
