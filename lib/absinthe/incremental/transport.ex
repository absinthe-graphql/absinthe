defmodule Absinthe.Incremental.Transport do
  @moduledoc """
  Protocol for incremental delivery across different transports.

  This module provides a behaviour and common functionality for implementing
  incremental delivery over various transport mechanisms (HTTP/SSE, WebSocket, etc.).

  ## Telemetry Events

  The following telemetry events are emitted during incremental delivery for
  instrumentation libraries (e.g., opentelemetry_absinthe):

  ### `[:absinthe, :incremental, :delivery, :initial]`

  Emitted when the initial response is sent.

  **Measurements:**
  - `system_time` - System time when the event occurred

  **Metadata:**
  - `operation_id` - Unique identifier for the operation
  - `has_next` - Boolean indicating if more payloads are expected
  - `pending_count` - Number of pending deferred/streamed operations
  - `response` - The initial response payload

  ### `[:absinthe, :incremental, :delivery, :payload]`

  Emitted when each incremental payload is delivered.

  **Measurements:**
  - `system_time` - System time when the event occurred
  - `duration` - Time taken to execute the deferred/streamed task (native units)

  **Metadata:**
  - `operation_id` - Unique identifier for the operation
  - `path` - GraphQL path to the deferred/streamed field
  - `label` - Label from @defer or @stream directive
  - `task_type` - `:defer` or `:stream`
  - `has_next` - Boolean indicating if more payloads are expected
  - `duration_ms` - Duration in milliseconds
  - `success` - Boolean indicating if the task succeeded
  - `response` - The incremental response payload

  ### `[:absinthe, :incremental, :delivery, :complete]`

  Emitted when incremental delivery completes successfully.

  **Measurements:**
  - `system_time` - System time when the event occurred
  - `duration` - Total duration of the incremental delivery (native units)

  **Metadata:**
  - `operation_id` - Unique identifier for the operation
  - `duration_ms` - Total duration in milliseconds

  ### `[:absinthe, :incremental, :delivery, :error]`

  Emitted when an error occurs during incremental delivery.

  **Measurements:**
  - `system_time` - System time when the event occurred
  - `duration` - Duration until the error occurred (native units)

  **Metadata:**
  - `operation_id` - Unique identifier for the operation
  - `duration_ms` - Duration in milliseconds
  - `error` - Map containing `:reason` and `:message` keys
  """

  alias Absinthe.Blueprint
  alias Absinthe.Incremental.{Config, Response}
  alias Absinthe.Streaming.Executor

  @type conn_or_socket :: Plug.Conn.t() | Phoenix.Socket.t() | any()
  @type state :: any()
  @type response :: map()

  @doc """
  Initialize the transport for incremental delivery.
  """
  @callback init(conn_or_socket, options :: Keyword.t()) :: {:ok, state} | {:error, term()}

  @doc """
  Send the initial response containing immediately available data.
  """
  @callback send_initial(state, response) :: {:ok, state} | {:error, term()}

  @doc """
  Send an incremental response containing deferred or streamed data.
  """
  @callback send_incremental(state, response) :: {:ok, state} | {:error, term()}

  @doc """
  Complete the incremental delivery stream.
  """
  @callback complete(state) :: :ok | {:error, term()}

  @doc """
  Handle errors during incremental delivery.
  """
  @callback handle_error(state, error :: term()) :: {:ok, state} | {:error, term()}

  @optional_callbacks [handle_error: 2]

  @default_timeout 30_000

  @telemetry_initial [:absinthe, :incremental, :delivery, :initial]
  @telemetry_payload [:absinthe, :incremental, :delivery, :payload]
  @telemetry_complete [:absinthe, :incremental, :delivery, :complete]
  @telemetry_error [:absinthe, :incremental, :delivery, :error]

  defmacro __using__(_opts) do
    quote do
      @behaviour Absinthe.Incremental.Transport

      alias Absinthe.Incremental.{Config, Response, ErrorHandler}

      # Telemetry event names for instrumentation (e.g., opentelemetry_absinthe)
      @telemetry_initial unquote(@telemetry_initial)
      @telemetry_payload unquote(@telemetry_payload)
      @telemetry_complete unquote(@telemetry_complete)
      @telemetry_error unquote(@telemetry_error)

      @doc """
      Handle a streaming response from the resolution phase.

      This is the main entry point for transport implementations.

      ## Options

      - `:timeout` - Maximum time to wait for streaming operations (default: 30s)
      - `:on_event` - Callback for monitoring events (Sentry, DataDog, etc.)
      - `:operation_id` - Unique identifier for tracking this operation

      ## Event Callbacks

      When `on_event` is provided, it will be called at each stage of incremental
      delivery with event type, payload, and metadata:

          on_event: fn event_type, payload, metadata ->
            case event_type do
              :initial -> Logger.info("Initial response sent")
              :incremental -> Logger.info("Incremental payload delivered")
              :complete -> Logger.info("Stream completed")
              :error -> Sentry.capture_message("GraphQL error", extra: payload)
            end
          end
      """
      def handle_streaming_response(conn_or_socket, blueprint, options \\ []) do
        timeout = Keyword.get(options, :timeout, unquote(@default_timeout))
        started_at = System.monotonic_time(:millisecond)
        operation_id = Keyword.get(options, :operation_id, generate_operation_id())

        # Build config with on_event callback
        config = build_event_config(options)

        # Add tracking metadata to options
        options =
          options
          |> Keyword.put(:__config__, config)
          |> Keyword.put(:__started_at__, started_at)
          |> Keyword.put(:__operation_id__, operation_id)

        with {:ok, state} <- init(conn_or_socket, options),
             {:ok, state} <- send_initial_response(state, blueprint, options),
             {:ok, state} <- execute_and_stream_incremental(state, blueprint, timeout, options) do
          emit_complete_event(config, operation_id, started_at)
          complete(state)
        else
          {:error, reason} = error ->
            emit_error_event(config, reason, operation_id, started_at)
            handle_transport_error(conn_or_socket, error, options)
        end
      end

      defp build_event_config(options) do
        case Keyword.get(options, :on_event) do
          nil -> nil
          callback when is_function(callback, 3) -> Config.from_options(on_event: callback)
          _ -> nil
        end
      end

      defp generate_operation_id do
        Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
      end

      defp send_initial_response(state, blueprint, options) do
        initial = Response.build_initial(blueprint)

        config = Keyword.get(options, :__config__)
        operation_id = Keyword.get(options, :__operation_id__)

        metadata = %{
          operation_id: operation_id,
          has_next: Map.get(initial, :hasNext, false),
          pending_count: length(Map.get(initial, :pending, []))
        }

        # Emit telemetry event for instrumentation
        :telemetry.execute(
          @telemetry_initial,
          %{system_time: System.system_time()},
          Map.merge(metadata, %{response: initial})
        )

        # Emit to custom on_event callback
        Config.emit_event(config, :initial, initial, metadata)

        send_initial(state, initial)
      end

      # Execute deferred/streamed tasks and deliver results as they complete
      defp execute_and_stream_incremental(state, blueprint, timeout, options) do
        streaming_context = get_streaming_context(blueprint)

        all_tasks =
          Map.get(streaming_context, :deferred_tasks, []) ++
            Map.get(streaming_context, :stream_tasks, [])

        if Enum.empty?(all_tasks) do
          {:ok, state}
        else
          execute_tasks_with_streaming(state, all_tasks, timeout, options)
        end
      end

      # Execute tasks using configurable executor for controlled concurrency
      defp execute_tasks_with_streaming(state, tasks, timeout, options) do
        config = Keyword.get(options, :__config__)
        operation_id = Keyword.get(options, :__operation_id__)
        started_at = Keyword.get(options, :__started_at__)
        schema = Keyword.get(options, :schema)

        # Get configurable executor (defaults to TaskExecutor)
        executor = Absinthe.Streaming.Executor.get_executor(schema, options)
        executor_opts = [
          timeout: timeout,
          max_concurrency: System.schedulers_online() * 2
        ]

        tasks
        |> executor.execute(executor_opts)
        |> Enum.reduce_while({:ok, state}, fn task_result, {:ok, acc_state} ->
          case task_result.success do
            true ->
              case send_task_result_from_executor(
                     acc_state,
                     task_result,
                     config,
                     operation_id
                   ) do
                {:ok, new_state} -> {:cont, {:ok, new_state}}
                {:error, _} = error -> {:halt, error}
              end

            false ->
              # Handle errors (timeout, exit, etc.)
              error_response = build_error_response_from_executor(task_result)
              emit_error_event(config, task_result.result, operation_id, started_at)

              case send_incremental(acc_state, error_response) do
                {:ok, new_state} -> {:cont, {:ok, new_state}}
                error -> {:halt, error}
              end
          end
        end)
      end

      # Send task result from TaskExecutor output
      defp send_task_result_from_executor(state, task_result, config, operation_id) do
        task = task_result.task
        result = task_result.result
        has_next = task_result.has_next
        duration_ms = task_result.duration_ms

        response = build_task_response(task, result, has_next)

        metadata = %{
          operation_id: operation_id,
          path: task.path,
          label: task.label,
          task_type: task.type,
          has_next: has_next,
          duration_ms: duration_ms,
          success: true
        }

        # Emit telemetry event for instrumentation
        :telemetry.execute(
          @telemetry_payload,
          %{
            system_time: System.system_time(),
            duration: duration_ms * 1_000_000
          },
          Map.merge(metadata, %{response: response})
        )

        # Emit to custom on_event callback
        Config.emit_event(config, :incremental, response, metadata)

        send_incremental(state, response)
      end

      # Build error response from TaskExecutor result
      defp build_error_response_from_executor(task_result) do
        error_message =
          case task_result.result do
            {:error, :timeout} -> "Operation timed out"
            {:error, {:exit, reason}} -> "Operation failed: #{inspect(reason)}"
            {:error, msg} when is_binary(msg) -> msg
            {:error, other} -> inspect(other)
          end

        Response.build_error(
          [%{message: error_message}],
          (task_result.task && task_result.task.path) || [],
          task_result.task && task_result.task.label,
          task_result.has_next
        )
      end

      # Build the appropriate response based on task type and result
      defp build_task_response(task, {:ok, result}, has_next) do
        case task.type do
          :defer ->
            Response.build_incremental(
              result.data,
              result.path,
              result.label,
              has_next
            )

          :stream ->
            Response.build_stream_incremental(
              result.items,
              result.path,
              result.label,
              has_next
            )
        end
      end

      defp build_task_response(task, {:error, error}, has_next) do
        errors =
          case error do
            %{message: _} = err -> [err]
            message when is_binary(message) -> [%{message: message}]
            other -> [%{message: inspect(other)}]
          end

        Response.build_error(
          errors,
          task.path,
          task.label,
          has_next
        )
      end

      defp get_streaming_context(blueprint) do
        get_in(blueprint.execution.context, [:__streaming__]) || %{}
      end

      defp handle_transport_error(conn_or_socket, error, options) do
        if function_exported?(__MODULE__, :handle_error, 2) do
          with {:ok, state} <- init(conn_or_socket, options) do
            apply(__MODULE__, :handle_error, [state, error])
          end
        else
          error
        end
      end

      defp emit_complete_event(config, operation_id, started_at) do
        duration_ms = System.monotonic_time(:millisecond) - started_at

        metadata = %{
          operation_id: operation_id,
          duration_ms: duration_ms
        }

        # Emit telemetry event for instrumentation
        :telemetry.execute(
          @telemetry_complete,
          %{
            system_time: System.system_time(),
            # Convert to native time units
            duration: duration_ms * 1_000_000
          },
          metadata
        )

        # Emit to custom on_event callback
        Config.emit_event(config, :complete, %{}, metadata)
      end

      defp emit_error_event(config, reason, operation_id, started_at) do
        duration_ms = System.monotonic_time(:millisecond) - started_at

        payload = %{
          reason: reason,
          message: format_error_message(reason)
        }

        metadata = %{
          operation_id: operation_id,
          duration_ms: duration_ms
        }

        # Emit telemetry event for instrumentation
        :telemetry.execute(
          @telemetry_error,
          %{
            system_time: System.system_time(),
            # Convert to native time units
            duration: duration_ms * 1_000_000
          },
          Map.merge(metadata, %{error: payload})
        )

        # Emit to custom on_event callback
        Config.emit_event(config, :error, payload, metadata)
      end

      defp format_error_message(:timeout), do: "Operation timed out"
      defp format_error_message({:error, msg}) when is_binary(msg), do: msg
      defp format_error_message(reason), do: inspect(reason)

      defoverridable handle_streaming_response: 3
    end
  end

  @doc """
  Check if a blueprint has incremental delivery enabled.
  """
  @spec incremental_delivery_enabled?(Blueprint.t()) :: boolean()
  def incremental_delivery_enabled?(blueprint) do
    get_in(blueprint.execution, [:incremental_delivery]) == true
  end

  @doc """
  Get the operation ID for tracking incremental delivery.
  """
  @spec get_operation_id(Blueprint.t()) :: String.t() | nil
  def get_operation_id(blueprint) do
    get_in(blueprint.execution.context, [:__streaming__, :operation_id])
  end

  @doc """
  Get streaming context from a blueprint.
  """
  @spec get_streaming_context(Blueprint.t()) :: map()
  def get_streaming_context(blueprint) do
    get_in(blueprint.execution.context, [:__streaming__]) || %{}
  end

  @doc """
  Execute incremental delivery for a blueprint.

  This is the main entry point that transport implementations call.
  """
  @spec execute(module(), conn_or_socket, Blueprint.t(), Keyword.t()) ::
          {:ok, state} | {:error, term()}
  def execute(transport_module, conn_or_socket, blueprint, options \\ []) do
    if incremental_delivery_enabled?(blueprint) do
      transport_module.handle_streaming_response(conn_or_socket, blueprint, options)
    else
      {:error, :incremental_delivery_not_enabled}
    end
  end

  @doc """
  Create a simple collector that accumulates all incremental responses.

  Useful for testing and non-streaming contexts.
  """
  @spec collect_all(Blueprint.t(), Keyword.t()) :: {:ok, map()} | {:error, term()}
  def collect_all(blueprint, options \\ []) do
    timeout = Keyword.get(options, :timeout, @default_timeout)
    schema = Keyword.get(options, :schema)
    streaming_context = get_streaming_context(blueprint)

    initial = Response.build_initial(blueprint)

    all_tasks =
      Map.get(streaming_context, :deferred_tasks, []) ++
        Map.get(streaming_context, :stream_tasks, [])

    # Use configurable executor (defaults to TaskExecutor)
    executor = Executor.get_executor(schema, options)
    incremental_results =
      all_tasks
      |> executor.execute(timeout: timeout)
      |> Enum.map(fn task_result ->
        task = task_result.task

        case task_result.result do
          {:ok, result} ->
            %{
              type: task.type,
              label: task.label,
              path: task.path,
              data: Map.get(result, :data),
              items: Map.get(result, :items),
              errors: Map.get(result, :errors)
            }

          {:error, error} ->
            error_msg =
              case error do
                :timeout -> "Operation timed out"
                {:exit, reason} -> "Task failed: #{inspect(reason)}"
                msg when is_binary(msg) -> msg
                other -> inspect(other)
              end

            %{
              type: task && task.type,
              label: task && task.label,
              path: task && task.path,
              errors: [%{message: error_msg}]
            }
        end
      end)

    {:ok,
     %{
       initial: initial,
       incremental: incremental_results,
       hasNext: false
     }}
  end
end
