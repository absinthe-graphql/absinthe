defmodule Absinthe.Phase.Document.Execution.StreamingResolution do
  @moduledoc """
  Resolution phase with support for @defer and @stream directives.
  Replaces standard resolution when incremental delivery is enabled.
  
  This phase detects @defer and @stream directives in the query and sets up
  the execution context for incremental delivery. The actual streaming happens
  through the transport layer.
  """
  
  use Absinthe.Phase
  alias Absinthe.{Blueprint, Phase}
  alias Absinthe.Phase.Document.Execution.Resolution
  
  @defer_directive "defer"
  @stream_directive "stream"
  
  @doc """
  Run the streaming resolution phase.
  
  If no streaming directives are detected, falls back to standard resolution.
  Otherwise, sets up the blueprint for incremental delivery.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(blueprint, options \\ []) do
    case detect_streaming_directives(blueprint) do
      true ->
        run_streaming(blueprint, options)
      
      false ->
        # No streaming directives, use standard resolution
        Resolution.run(blueprint, options)
    end
  end
  
  # Detect if the query contains @defer or @stream directives
  defp detect_streaming_directives(blueprint) do
    blueprint
    |> Blueprint.prewalk(false, fn
      %{flags: %{defer: _}}, _acc -> {nil, true}
      %{flags: %{stream: _}}, _acc -> {nil, true}
      node, acc -> {node, acc}
    end)
    |> elem(1)
  end
  
  defp run_streaming(blueprint, options) do
    blueprint
    |> init_streaming_context()
    |> setup_initial_resolution()
    |> Resolution.run(options)
    |> setup_deferred_execution()
  end
  
  # Initialize the streaming context in the blueprint
  defp init_streaming_context(blueprint) do
    streaming_context = %{
      deferred_fragments: [],
      streamed_fields: [],
      pending_operations: [],
      operation_id: generate_operation_id()
    }
    
    put_in(blueprint.execution.context[:__streaming__], streaming_context)
  end
  
  # Setup the blueprint for initial resolution
  defp setup_initial_resolution(blueprint) do
    Blueprint.prewalk(blueprint, fn
      # Handle deferred fragments - mark them for skipping in initial pass
      %{flags: %{defer: defer_config}} = node when defer_config.enabled ->
        streaming_context = get_streaming_context(blueprint)
        deferred_fragment = %{
          node: node,
          label: defer_config.label,
          path: current_path(node)
        }
        
        # Add to deferred list
        updated_context = update_in(
          streaming_context.deferred_fragments,
          &[deferred_fragment | &1]
        )
        blueprint = put_streaming_context(blueprint, updated_context)
        
        # Mark node to skip in initial resolution
        %{node | flags: Map.put(node.flags, :skip_initial, true)}
      
      # Handle streamed fields - limit to initial_count
      %{flags: %{stream: stream_config}} = node when stream_config.enabled ->
        streaming_context = get_streaming_context(blueprint)
        streamed_field = %{
          node: node,
          label: stream_config.label,
          initial_count: stream_config.initial_count,
          path: current_path(node)
        }
        
        # Add to streamed list
        updated_context = update_in(
          streaming_context.streamed_fields,
          &[streamed_field | &1]
        )
        blueprint = put_streaming_context(blueprint, updated_context)
        
        # Mark node with streaming limit
        %{node | flags: Map.put(node.flags, :stream_initial_count, stream_config.initial_count)}
      
      node ->
        node
    end)
  end
  
  # Setup deferred execution after initial resolution
  defp setup_deferred_execution({:ok, blueprint}) do
    streaming_context = get_streaming_context(blueprint)
    
    if has_pending_operations?(streaming_context) do
      blueprint
      |> setup_deferred_tasks()
      |> setup_stream_tasks()
      |> mark_as_streaming()
    else
      {:ok, blueprint}
    end
  end
  
  defp setup_deferred_execution(error), do: error
  
  defp setup_deferred_tasks(blueprint) do
    streaming_context = get_streaming_context(blueprint)
    
    deferred_tasks = Enum.map(streaming_context.deferred_fragments, fn fragment ->
      create_deferred_task(fragment, blueprint)
    end)
    
    updated_context = Map.put(streaming_context, :deferred_tasks, deferred_tasks)
    put_streaming_context(blueprint, updated_context)
  end
  
  defp setup_stream_tasks(blueprint) do
    streaming_context = get_streaming_context(blueprint)
    
    stream_tasks = Enum.map(streaming_context.streamed_fields, fn field ->
      create_stream_task(field, blueprint)
    end)
    
    updated_context = Map.put(streaming_context, :stream_tasks, stream_tasks)
    put_streaming_context(blueprint, updated_context)
  end
  
  defp create_deferred_task(fragment, blueprint) do
    %{
      type: :defer,
      label: fragment.label,
      path: fragment.path,
      node: fragment.node,
      status: :pending,
      execute: fn ->
        # This will be executed asynchronously by the transport layer
        resolve_deferred_fragment(fragment, blueprint)
      end
    }
  end
  
  defp create_stream_task(field, blueprint) do
    %{
      type: :stream,
      label: field.label,
      path: field.path,
      node: field.node,
      initial_count: field.initial_count,
      status: :pending,
      execute: fn ->
        # This will be executed asynchronously by the transport layer
        resolve_streamed_field(field, blueprint)
      end
    }
  end
  
  defp resolve_deferred_fragment(fragment, blueprint) do
    # Remove the skip flag and resolve the fragment
    node = %{fragment.node | flags: Map.delete(fragment.node.flags, :skip_initial)}
    
    # Create a sub-blueprint for this fragment
    sub_blueprint = %{blueprint | 
      execution: %{blueprint.execution |
        fragments: [node]
      }
    }
    
    # Run resolution on the fragment
    case Resolution.run(sub_blueprint, []) do
      {:ok, resolved_blueprint} ->
        extract_fragment_result(resolved_blueprint, fragment.path)
      
      error ->
        error
    end
  end
  
  defp resolve_streamed_field(field, blueprint) do
    # Get the full list from the resolution
    # This assumes the field was already partially resolved
    node = field.node
    
    # Create a sub-blueprint for remaining items
    sub_blueprint = %{blueprint |
      execution: %{blueprint.execution |
        fields: [node],
        stream_offset: field.initial_count
      }
    }
    
    # Run resolution for remaining items
    case Resolution.run(sub_blueprint, []) do
      {:ok, resolved_blueprint} ->
        extract_streamed_items(resolved_blueprint, field.path, field.initial_count)
      
      error ->
        error
    end
  end
  
  defp extract_fragment_result(blueprint, path) do
    # Extract the resolved fragment data from the blueprint
    # This will be formatted by the transport layer
    %{
      data: get_in(blueprint.result, [:data | path]),
      path: path
    }
  end
  
  defp extract_streamed_items(blueprint, path, offset) do
    # Extract the streamed items from the blueprint
    %{
      items: get_in(blueprint.result, [:data | path]) |> Enum.drop(offset),
      path: path
    }
  end
  
  defp mark_as_streaming(blueprint) do
    {:ok, put_in(blueprint.execution[:incremental_delivery], true)}
  end
  
  defp has_pending_operations?(streaming_context) do
    not Enum.empty?(streaming_context.deferred_fragments) or
    not Enum.empty?(streaming_context.streamed_fields)
  end
  
  defp get_streaming_context(blueprint) do
    get_in(blueprint.execution.context, [:__streaming__]) || %{}
  end
  
  defp put_streaming_context(blueprint, context) do
    put_in(blueprint.execution.context[:__streaming__], context)
  end
  
  defp current_path(node) do
    # Extract the current path from the node
    # This would need to be implemented based on the actual Blueprint structure
    Map.get(node, :path, [])
  end
  
  defp generate_operation_id do
    # Generate a unique operation ID for tracking
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end