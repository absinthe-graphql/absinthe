defmodule Absinthe.Streaming.Delivery do
  @moduledoc """
  Unified incremental delivery for subscriptions.

  This module handles delivering GraphQL results incrementally via pubsub when
  a subscription document contains @defer or @stream directives. It calls
  `publish_subscription/2` multiple times with the standard GraphQL incremental
  response format:

  1. Initial payload: `%{data: ..., pending: [...], hasNext: true}`
  2. Incremental payloads: `%{incremental: [...], hasNext: boolean}`
  3. Final payload: `%{hasNext: false}`

  This format is the standard GraphQL incremental delivery format that compliant
  clients (Apollo, Relay, urql) already understand.

  ## Usage

  This module is used automatically by `Absinthe.Subscription.Local` when a
  subscription document contains @defer or @stream directives. You typically
  don't need to call it directly.

      # In Subscription.Local.run_docset/3
      if Absinthe.Streaming.has_streaming_tasks?(blueprint) do
        Absinthe.Streaming.Delivery.deliver(pubsub, topic, blueprint)
      else
        pubsub.publish_subscription(topic, result)
      end

  ## How It Works

  1. Builds the initial response using `Absinthe.Incremental.Response.build_initial/1`
  2. Publishes initial response via `pubsub.publish_subscription(topic, initial)`
  3. Executes deferred/streamed tasks using `TaskExecutor.execute_stream/2`
  4. For each result, builds an incremental payload and publishes it
  5. Existing pubsub implementations work unchanged - they just deliver each message

  ## Backwards Compatibility

  Existing pubsub implementations don't need any changes. The same
  `publish_subscription(topic, data)` callback is used - it's just called
  multiple times with different payloads.
  """

  require Logger

  alias Absinthe.Blueprint
  alias Absinthe.Incremental.Response
  alias Absinthe.Streaming
  alias Absinthe.Streaming.Executor

  @default_timeout 30_000

  @type delivery_option ::
          {:timeout, non_neg_integer()}
          | {:max_concurrency, pos_integer()}
          | {:executor, module()}
          | {:schema, module()}

  @doc """
  Deliver incremental results via pubsub.

  Calls `pubsub.publish_subscription/2` multiple times with the standard
  GraphQL incremental delivery format.

  ## Options

  - `:timeout` - Maximum time to wait for each deferred task (default: #{@default_timeout}ms)
  - `:max_concurrency` - Maximum concurrent tasks (default: CPU count * 2)
  - `:executor` - Custom executor module (default: uses schema config or `TaskExecutor`)
  - `:schema` - Schema module for looking up executor config

  ## Returns

  - `:ok` on successful delivery
  - `{:error, reason}` if delivery fails
  """
  @spec deliver(module(), String.t(), Blueprint.t(), [delivery_option()]) ::
          :ok | {:error, term()}
  def deliver(pubsub, topic, blueprint, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    # 1. Build and send initial response
    initial = Response.build_initial(blueprint)

    case pubsub.publish_subscription(topic, initial) do
      :ok ->
        # 2. Execute and send incremental payloads
        deliver_incremental(pubsub, topic, blueprint, timeout, opts)

      error ->
        Logger.error("Failed to publish initial subscription payload: #{inspect(error)}")
        {:error, {:initial_delivery_failed, error}}
    end
  end

  @doc """
  Collect all incremental results without streaming.

  Executes all deferred/streamed tasks and returns the complete result
  as a single payload. Useful when you want the full result immediately
  without multiple payloads.

  ## Options

  Same as `deliver/4`.

  ## Returns

  A map with the complete result:

      %{
        data: <initial_data merged with deferred data>,
        errors: [...] # if any
      }
  """
  @spec collect_all(Blueprint.t(), [delivery_option()]) :: {:ok, map()} | {:error, term()}
  def collect_all(blueprint, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    schema = Keyword.get(opts, :schema)
    executor = Executor.get_executor(schema, opts)
    tasks = Streaming.get_streaming_tasks(blueprint)

    # Get initial data
    initial = Response.build_initial(blueprint)
    initial_data = Map.get(initial, :data, %{})
    initial_errors = Map.get(initial, :errors, [])

    # Execute all tasks and collect results using configurable executor
    results = executor.execute(tasks, timeout: timeout) |> Enum.to_list()

    # Merge results into final data
    {final_data, final_errors} =
      Enum.reduce(results, {initial_data, initial_errors}, fn task_result, {data, errors} ->
        case task_result.result do
          {:ok, result} ->
            # Merge deferred data at the correct path
            merged_data = merge_at_path(data, task_result.task.path, result)
            result_errors = Map.get(result, :errors, [])
            {merged_data, errors ++ result_errors}

          {:error, error} ->
            error_entry = %{
              message: format_error(error),
              path: task_result.task.path
            }

            {data, errors ++ [error_entry]}
        end
      end)

    result =
      if Enum.empty?(final_errors) do
        %{data: final_data}
      else
        %{data: final_data, errors: final_errors}
      end

    {:ok, result}
  end

  # Deliver incremental payloads
  defp deliver_incremental(pubsub, topic, blueprint, timeout, opts) do
    tasks = Streaming.get_streaming_tasks(blueprint)

    if Enum.empty?(tasks) do
      :ok
    else
      do_deliver_incremental(pubsub, topic, tasks, timeout, opts)
    end
  end

  defp do_deliver_incremental(pubsub, topic, tasks, timeout, opts) do
    max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online() * 2)
    schema = Keyword.get(opts, :schema)
    executor = Executor.get_executor(schema, opts)

    executor_opts = [timeout: timeout, max_concurrency: max_concurrency]

    result =
      tasks
      |> executor.execute(executor_opts)
      |> Enum.reduce_while(:ok, fn task_result, :ok ->
        payload = build_incremental_payload(task_result)

        case pubsub.publish_subscription(topic, payload) do
          :ok ->
            {:cont, :ok}

          error ->
            Logger.error("Failed to publish incremental payload: #{inspect(error)}")
            {:halt, {:error, {:incremental_delivery_failed, error}}}
        end
      end)

    result
  end

  # Build an incremental payload from a task result
  defp build_incremental_payload(task_result) do
    case task_result.result do
      {:ok, result} ->
        build_success_payload(task_result.task, result, task_result.has_next)

      {:error, error} ->
        build_error_payload(task_result.task, error, task_result.has_next)
    end
  end

  defp build_success_payload(task, result, has_next) do
    case task.type do
      :defer ->
        Response.build_incremental(
          Map.get(result, :data),
          Map.get(result, :path, task.path),
          Map.get(result, :label, task.label),
          has_next
        )

      :stream ->
        Response.build_stream_incremental(
          Map.get(result, :items, []),
          Map.get(result, :path, task.path),
          Map.get(result, :label, task.label),
          has_next
        )
    end
  end

  defp build_error_payload(task, error, has_next) do
    errors = [%{message: format_error(error), path: task && task.path}]
    path = (task && task.path) || []
    label = task && task.label

    Response.build_error(errors, path, label, has_next)
  end

  # Merge data at a specific path
  defp merge_at_path(data, [], result) do
    case result do
      %{data: new_data} when is_map(new_data) -> Map.merge(data, new_data)
      %{items: items} when is_list(items) -> items
      _ -> data
    end
  end

  defp merge_at_path(data, [key | rest], result) when is_map(data) do
    current = Map.get(data, key, %{})
    updated = merge_at_path(current, rest, result)
    Map.put(data, key, updated)
  end

  defp merge_at_path(data, _path, _result), do: data

  # Format error for display
  defp format_error(:timeout), do: "Operation timed out"
  defp format_error({:exit, reason}), do: "Task failed: #{inspect(reason)}"
  defp format_error(%{message: msg}), do: msg
  defp format_error(error) when is_binary(error), do: error
  defp format_error(error), do: inspect(error)
end
