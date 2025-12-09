defmodule Absinthe.Incremental.Transport do
  @moduledoc """
  Protocol for incremental delivery across different transports.
  
  This module provides a behaviour and common functionality for implementing
  incremental delivery over various transport mechanisms (HTTP/SSE, WebSocket, etc.).
  """
  
  alias Absinthe.Blueprint
  alias Absinthe.Incremental.Response
  
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
  
  defmacro __using__(_opts) do
    quote do
      @behaviour Absinthe.Incremental.Transport
      
      alias Absinthe.Incremental.Response
      
      @doc """
      Handle a streaming response from the resolution phase.
      
      This is the main entry point for transport implementations.
      """
      def handle_streaming_response(conn_or_socket, blueprint, options \\ []) do
        with {:ok, state} <- init(conn_or_socket, options),
             {:ok, state} <- send_initial_response(state, blueprint),
             {:ok, state} <- stream_incremental_responses(state, blueprint) do
          complete(state)
        else
          {:error, reason} = error ->
            handle_transport_error(conn_or_socket, error)
        end
      end
      
      defp send_initial_response(state, blueprint) do
        initial = Response.build_initial(blueprint)
        send_initial(state, initial)
      end
      
      defp stream_incremental_responses(state, blueprint) do
        streaming_context = get_streaming_context(blueprint)
        
        # Start async processing of deferred and streamed operations
        state = 
          state
          |> process_deferred_operations(streaming_context)
          |> process_streamed_operations(streaming_context)
        
        {:ok, state}
      end
      
      defp process_deferred_operations(state, streaming_context) do
        tasks = Map.get(streaming_context, :deferred_tasks, [])
        
        Enum.reduce(tasks, state, fn task, acc_state ->
          Task.async(fn ->
            case task.execute.() do
              {:ok, result} ->
                response = Response.build_incremental(
                  result.data,
                  task.path,
                  task.label,
                  has_more_pending?(streaming_context, task)
                )
                send_incremental(acc_state, response)
                
              {:error, errors} ->
                response = Response.build_error(
                  errors,
                  task.path,
                  task.label,
                  has_more_pending?(streaming_context, task)
                )
                send_incremental(acc_state, response)
            end
          end)
          
          acc_state
        end)
      end
      
      defp process_streamed_operations(state, streaming_context) do
        tasks = Map.get(streaming_context, :stream_tasks, [])
        
        Enum.reduce(tasks, state, fn task, acc_state ->
          Task.async(fn ->
            case task.execute.() do
              {:ok, result} ->
                response = Response.build_stream_incremental(
                  result.items,
                  task.path,
                  task.label,
                  has_more_pending?(streaming_context, task)
                )
                send_incremental(acc_state, response)
                
              {:error, errors} ->
                response = Response.build_error(
                  errors,
                  task.path,
                  task.label,
                  has_more_pending?(streaming_context, task)
                )
                send_incremental(acc_state, response)
            end
          end)
          
          acc_state
        end)
      end
      
      defp has_more_pending?(streaming_context, current_task) do
        all_tasks = 
          Map.get(streaming_context, :deferred_tasks, []) ++
          Map.get(streaming_context, :stream_tasks, [])
        
        # Check if there are other pending tasks after this one
        Enum.any?(all_tasks, fn task ->
          task != current_task and task.status == :pending
        end)
      end
      
      defp get_streaming_context(blueprint) do
        get_in(blueprint, [:execution, :context, :__streaming__]) || %{}
      end
      
      defp handle_transport_error(conn_or_socket, error) do
        if function_exported?(__MODULE__, :handle_error, 2) do
          apply(__MODULE__, :handle_error, [conn_or_socket, error])
        else
          error
        end
      end
      
      defoverridable [handle_streaming_response: 3]
    end
  end
  
  @doc """
  Check if a blueprint has incremental delivery enabled.
  """
  @spec incremental_delivery_enabled?(Blueprint.t()) :: boolean()
  def incremental_delivery_enabled?(blueprint) do
    get_in(blueprint, [:execution, :incremental_delivery]) == true
  end
  
  @doc """
  Get the operation ID for tracking incremental delivery.
  """
  @spec get_operation_id(Blueprint.t()) :: String.t() | nil
  def get_operation_id(blueprint) do
    get_in(blueprint, [:execution, :context, :__streaming__, :operation_id])
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
end