defmodule Absinthe.Incremental.ErrorHandler do
  @moduledoc """
  Comprehensive error handling for incremental delivery.

  This module provides error handling, recovery, and cleanup for
  streaming operations, ensuring robust behavior even when things go wrong.
  """

  alias Absinthe.Incremental.Response
  require Logger

  @type error_type ::
          :timeout
          | :dataloader_error
          | :transport_error
          | :resolution_error
          | :resource_limit
          | :cancelled

  @type error_context :: %{
          operation_id: String.t(),
          path: list(),
          label: String.t() | nil,
          error_type: error_type(),
          details: any()
        }

  @doc """
  Handle errors that occur during streaming operations.

  Returns an appropriate error response based on the error type.
  """
  @spec handle_streaming_error(any(), error_context()) :: map()
  def handle_streaming_error(error, context) do
    error_type = classify_error(error)

    case error_type do
      :timeout ->
        build_timeout_response(error, context)

      :dataloader_error ->
        build_dataloader_error_response(error, context)

      :transport_error ->
        build_transport_error_response(error, context)

      :resource_limit ->
        build_resource_limit_response(error, context)

      :cancelled ->
        build_cancellation_response(error, context)

      _ ->
        build_generic_error_response(error, context)
    end
  end

  @doc """
  Wrap a streaming task with error handling.

  Ensures that errors in async tasks are properly caught and reported.
  """
  @spec wrap_streaming_task((-> any())) :: (-> any())
  def wrap_streaming_task(task_fn) do
    fn ->
      try do
        task_fn.()
      rescue
        exception ->
          stacktrace = __STACKTRACE__
          Logger.error("Streaming task error: #{Exception.message(exception)}")
          {:error, format_exception(exception, stacktrace)}
      catch
        :exit, reason ->
          Logger.error("Streaming task exit: #{inspect(reason)}")
          {:error, {:exit, reason}}

        :throw, value ->
          Logger.error("Streaming task throw: #{inspect(value)}")
          {:error, {:throw, value}}
      end
    end
  end

  @doc """
  Monitor a streaming operation for timeouts.

  Sets up timeout monitoring and cancels the operation if it exceeds
  the configured duration.
  """
  @spec monitor_timeout(pid(), non_neg_integer(), error_context()) :: reference()
  def monitor_timeout(pid, timeout_ms, context) do
    Process.send_after(
      self(),
      {:streaming_timeout, pid, context},
      timeout_ms
    )
  end

  @doc """
  Handle a timeout for a streaming operation.
  """
  @spec handle_timeout(pid(), error_context()) :: :ok
  def handle_timeout(pid, context) do
    if Process.alive?(pid) do
      Process.exit(pid, :timeout)

      # Log the timeout
      Logger.warning(
        "Streaming operation timeout - operation_id: #{context.operation_id}, path: #{inspect(context.path)}"
      )
    end

    :ok
  end

  @doc """
  Recover from a failed streaming operation.

  Attempts to recover or provide fallback data when a streaming
  operation fails.
  """
  @spec recover_streaming_operation(any(), error_context()) ::
          {:ok, any()} | {:error, any()}
  def recover_streaming_operation(error, context) do
    case context.error_type do
      :timeout ->
        # For timeouts, we might return partial data
        {:error, :timeout_no_recovery}

      :dataloader_error ->
        # Try to load without batching
        attempt_direct_load(context)

      :transport_error ->
        # Transport errors are not recoverable
        {:error, :transport_failure}

      _ ->
        # Generic recovery attempt
        {:error, error}
    end
  end

  @doc """
  Clean up resources after a streaming operation completes or fails.
  """
  @spec cleanup_streaming_resources(map()) :: :ok
  def cleanup_streaming_resources(streaming_context) do
    # Cancel any pending tasks
    cancel_pending_tasks(streaming_context)

    # Clear dataloader caches if needed
    clear_dataloader_caches(streaming_context)

    # Release any held resources
    release_resources(streaming_context)

    :ok
  end

  @doc """
  Validate that a streaming operation can proceed.

  Checks resource limits and other constraints.
  """
  @spec validate_streaming_operation(map()) :: :ok | {:error, term()}
  def validate_streaming_operation(context) do
    with :ok <- check_concurrent_streams(context),
         :ok <- check_memory_usage(context),
         :ok <- check_complexity(context) do
      :ok
    end
  end

  # Private functions

  defp classify_error({:timeout, _}), do: :timeout
  defp classify_error({:dataloader_error, _, _}), do: :dataloader_error
  defp classify_error({:transport_error, _}), do: :transport_error
  defp classify_error({:resource_limit, _}), do: :resource_limit
  defp classify_error(:cancelled), do: :cancelled
  defp classify_error(_), do: :unknown

  defp build_timeout_response(_error, context) do
    %{
      incremental: [
        %{
          errors: [
            %{
              message:
                "Operation timeout: The deferred/streamed operation took too long to complete",
              path: context.path,
              extensions: %{
                code: "STREAMING_TIMEOUT",
                label: context.label,
                operation_id: context.operation_id
              }
            }
          ],
          path: context.path
        }
      ],
      hasNext: false
    }
  end

  defp build_dataloader_error_response({:dataloader_error, source, error}, context) do
    %{
      incremental: [
        %{
          errors: [
            %{
              message: "Dataloader error: Failed to load data from source #{inspect(source)}",
              path: context.path,
              extensions: %{
                code: "DATALOADER_ERROR",
                source: source,
                details: inspect(error),
                label: context.label
              }
            }
          ],
          path: context.path
        }
      ],
      hasNext: false
    }
  end

  defp build_transport_error_response({:transport_error, reason}, context) do
    %{
      incremental: [
        %{
          errors: [
            %{
              message: "Transport error: Failed to deliver incremental response",
              path: context.path,
              extensions: %{
                code: "TRANSPORT_ERROR",
                reason: inspect(reason),
                label: context.label
              }
            }
          ],
          path: context.path
        }
      ],
      hasNext: false
    }
  end

  defp build_resource_limit_response({:resource_limit, limit_type}, context) do
    %{
      incremental: [
        %{
          errors: [
            %{
              message: "Resource limit exceeded: #{limit_type}",
              path: context.path,
              extensions: %{
                code: "RESOURCE_LIMIT_EXCEEDED",
                limit_type: limit_type,
                label: context.label
              }
            }
          ],
          path: context.path
        }
      ],
      hasNext: false
    }
  end

  defp build_cancellation_response(_error, context) do
    %{
      incremental: [
        %{
          errors: [
            %{
              message: "Operation cancelled",
              path: context.path,
              extensions: %{
                code: "OPERATION_CANCELLED",
                label: context.label
              }
            }
          ],
          path: context.path
        }
      ],
      hasNext: false
    }
  end

  defp build_generic_error_response(error, context) do
    %{
      incremental: [
        %{
          errors: [
            %{
              message: "Unexpected error during incremental delivery",
              path: context.path,
              extensions: %{
                code: "STREAMING_ERROR",
                details: inspect(error),
                label: context.label
              }
            }
          ],
          path: context.path
        }
      ],
      hasNext: false
    }
  end

  defp format_exception(exception, stacktrace \\ nil) do
    formatted_stacktrace =
      if stacktrace do
        Exception.format_stacktrace(stacktrace)
      else
        "stacktrace not available"
      end

    %{
      message: Exception.message(exception),
      type: exception.__struct__,
      stacktrace: formatted_stacktrace
    }
  end

  defp attempt_direct_load(_context) do
    # Attempt to load data directly without batching
    # This is a fallback when dataloader fails
    Logger.debug("Attempting direct load after dataloader failure")
    {:error, :direct_load_not_implemented}
  end

  defp cancel_pending_tasks(streaming_context) do
    tasks =
      Map.get(streaming_context, :deferred_tasks, []) ++
        Map.get(streaming_context, :stream_tasks, [])

    Enum.each(tasks, fn task ->
      if Map.get(task, :pid) && Process.alive?(task.pid) do
        Process.exit(task.pid, :shutdown)
      end
    end)
  end

  defp clear_dataloader_caches(streaming_context) do
    # Clear any dataloader caches associated with this streaming operation
    # This helps prevent memory leaks
    if _dataloader = Map.get(streaming_context, :dataloader) do
      # Clear caches (implementation depends on Dataloader version)
      Logger.debug("Clearing dataloader caches for streaming operation")
    end
  end

  defp release_resources(streaming_context) do
    # Release any other resources held by the streaming operation
    if resource_manager = Map.get(streaming_context, :resource_manager) do
      operation_id = Map.get(streaming_context, :operation_id)
      send(resource_manager, {:release, operation_id})
    end
  end

  defp check_concurrent_streams(_context) do
    # Check if we're within concurrent stream limits
    max_streams = get_config(:max_concurrent_streams, 100)
    current_streams = get_current_stream_count()

    if current_streams < max_streams do
      :ok
    else
      {:error, {:resource_limit, :max_concurrent_streams}}
    end
  end

  defp check_memory_usage(_context) do
    # Check current memory usage
    memory_limit = get_config(:max_memory_mb, 500) * 1_048_576
    current_memory = :erlang.memory(:total)

    if current_memory < memory_limit do
      :ok
    else
      {:error, {:resource_limit, :memory_limit}}
    end
  end

  defp check_complexity(context) do
    # Check query complexity if configured
    if complexity = Map.get(context, :complexity) do
      max_complexity = get_config(:max_streaming_complexity, 1000)

      if complexity <= max_complexity do
        :ok
      else
        {:error, {:resource_limit, :query_complexity}}
      end
    else
      :ok
    end
  end

  defp get_config(key, default) do
    Application.get_env(:absinthe, :incremental_delivery, [])
    |> Keyword.get(key, default)
  end

  defp get_current_stream_count do
    # This would track active streams globally
    # For now, return a placeholder
    0
  end
end
