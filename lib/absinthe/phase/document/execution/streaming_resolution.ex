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
    |> collect_and_prepare_streaming_nodes()
    |> run_initial_resolution(options)
    |> setup_deferred_execution(options)
  end

  # Initialize the streaming context in the blueprint
  defp init_streaming_context(blueprint) do
    streaming_context = %{
      deferred_fragments: [],
      streamed_fields: [],
      deferred_tasks: [],
      stream_tasks: [],
      operation_id: generate_operation_id(),
      schema: blueprint.schema,
      # Store original operations for deferred re-resolution
      original_operations: blueprint.operations
    }

    updated_context = Map.put(blueprint.execution.context, :__streaming__, streaming_context)
    updated_execution = %{blueprint.execution | context: updated_context}
    %{blueprint | execution: updated_execution}
  end

  # Collect deferred/streamed nodes and prepare blueprint for initial resolution
  defp collect_and_prepare_streaming_nodes(blueprint) do
    # Track current path during traversal
    initial_acc = %{
      deferred_fragments: [],
      streamed_fields: [],
      path: []
    }

    {updated_blueprint, collected} =
      Blueprint.prewalk(blueprint, initial_acc, &collect_streaming_node/2)

    # Store collected nodes in streaming context
    streaming_context = get_streaming_context(updated_blueprint)

    updated_streaming_context = %{
      streaming_context
      | deferred_fragments: Enum.reverse(collected.deferred_fragments),
        streamed_fields: Enum.reverse(collected.streamed_fields)
    }

    put_streaming_context(updated_blueprint, updated_streaming_context)
  end

  # Collect streaming nodes during prewalk and mark them appropriately
  defp collect_streaming_node(node, acc) do
    case node do
      # Handle deferred fragments (inline or spread)
      %{flags: %{defer: %{enabled: true} = defer_config}} = fragment_node ->
        # Build path for this fragment
        path = build_node_path(fragment_node, acc.path)

        # Collect the deferred fragment info
        deferred_info = %{
          node: fragment_node,
          path: path,
          label: defer_config[:label],
          selections: get_selections(fragment_node)
        }

        # Mark the node to skip in initial resolution
        updated_node = mark_for_skip(fragment_node)
        updated_acc = %{acc | deferred_fragments: [deferred_info | acc.deferred_fragments]}

        {updated_node, updated_acc}

      # Handle streamed list fields
      %{flags: %{stream: %{enabled: true} = stream_config}} = field_node ->
        # Build path for this field
        path = build_node_path(field_node, acc.path)

        # Collect the streamed field info
        streamed_info = %{
          node: field_node,
          path: path,
          label: stream_config[:label],
          initial_count: stream_config[:initial_count] || 0
        }

        # Keep the field but mark it with stream config for partial resolution
        updated_node = mark_for_streaming(field_node, stream_config)
        updated_acc = %{acc | streamed_fields: [streamed_info | acc.streamed_fields]}

        {updated_node, updated_acc}

      # Track path through fields for accurate path building
      %Absinthe.Blueprint.Document.Field{name: name} = field_node ->
        updated_acc = %{acc | path: acc.path ++ [name]}
        {field_node, updated_acc}

      # Pass through other nodes
      other ->
        {other, acc}
    end
  end

  # Mark a node to be skipped in initial resolution
  defp mark_for_skip(node) do
    flags =
      node.flags
      |> Map.delete(:defer)
      |> Map.put(:__skip_initial__, true)

    %{node | flags: flags}
  end

  # Mark a field for streaming (partial resolution)
  defp mark_for_streaming(node, stream_config) do
    flags =
      node.flags
      |> Map.delete(:stream)
      |> Map.put(:__stream_config__, stream_config)

    %{node | flags: flags}
  end

  # Build the path for a node
  defp build_node_path(%{name: name}, parent_path) when is_binary(name) do
    parent_path ++ [name]
  end

  defp build_node_path(%Absinthe.Blueprint.Document.Fragment.Spread{name: name}, parent_path) do
    parent_path ++ [name]
  end

  defp build_node_path(_node, parent_path) do
    parent_path
  end

  # Get selections from a fragment node
  defp get_selections(%{selections: selections}) when is_list(selections), do: selections
  defp get_selections(_), do: []

  # Run initial resolution, skipping deferred content
  defp run_initial_resolution(blueprint, options) do
    # Filter out deferred nodes before resolution
    filtered_blueprint = filter_deferred_selections(blueprint)

    # Run standard resolution on filtered blueprint
    Resolution.run(filtered_blueprint, options)
  end

  # Filter out selections that are marked for skipping
  defp filter_deferred_selections(blueprint) do
    Blueprint.prewalk(blueprint, fn
      # Skip nodes marked for deferral
      %{flags: %{__skip_initial__: true}} ->
        nil

      # For streamed fields, limit the resolution to initial_count
      %{flags: %{__stream_config__: config}} = node ->
        # The stream config is preserved, resolution middleware will handle limiting
        node

      node ->
        node
    end)
  end

  # Setup deferred execution after initial resolution
  defp setup_deferred_execution({:ok, blueprint}, options) do
    streaming_context = get_streaming_context(blueprint)

    if has_pending_operations?(streaming_context) do
      blueprint
      |> create_deferred_tasks(options)
      |> create_stream_tasks(options)
      |> mark_as_streaming()
    else
      {:ok, blueprint}
    end
  end

  defp setup_deferred_execution(error, _options), do: error

  # Create executable tasks for deferred fragments
  defp create_deferred_tasks(blueprint, options) do
    streaming_context = get_streaming_context(blueprint)

    deferred_tasks =
      Enum.map(streaming_context.deferred_fragments, fn fragment_info ->
        create_deferred_task(fragment_info, blueprint, options)
      end)

    updated_context = %{streaming_context | deferred_tasks: deferred_tasks}
    put_streaming_context(blueprint, updated_context)
  end

  # Create executable tasks for streamed fields
  defp create_stream_tasks(blueprint, options) do
    streaming_context = get_streaming_context(blueprint)

    stream_tasks =
      Enum.map(streaming_context.streamed_fields, fn field_info ->
        create_stream_task(field_info, blueprint, options)
      end)

    updated_context = %{streaming_context | stream_tasks: stream_tasks}
    put_streaming_context(blueprint, updated_context)
  end

  defp create_deferred_task(fragment_info, blueprint, options) do
    %{
      id: generate_task_id(),
      type: :defer,
      label: fragment_info.label,
      path: fragment_info.path,
      status: :pending,
      execute: fn ->
        resolve_deferred_fragment(fragment_info, blueprint, options)
      end
    }
  end

  defp create_stream_task(field_info, blueprint, options) do
    %{
      id: generate_task_id(),
      type: :stream,
      label: field_info.label,
      path: field_info.path,
      initial_count: field_info.initial_count,
      status: :pending,
      execute: fn ->
        resolve_streamed_field(field_info, blueprint, options)
      end
    }
  end

  # Resolve a deferred fragment by re-running resolution on just that fragment
  defp resolve_deferred_fragment(fragment_info, blueprint, options) do
    # Restore the original node without skip flag
    node = restore_deferred_node(fragment_info.node)

    # Get the parent data at this path from the initial result
    parent_data = get_parent_data(blueprint, fragment_info.path)

    # Create a focused blueprint for just this fragment's fields
    sub_blueprint = build_sub_blueprint(blueprint, node, parent_data, fragment_info.path)

    # Run resolution
    case Resolution.run(sub_blueprint, options) do
      {:ok, resolved_blueprint} ->
        {:ok, extract_fragment_result(resolved_blueprint, fragment_info)}

      {:error, _} = error ->
        error
    end
  rescue
    e ->
      {:error,
       %{
         message: Exception.message(e),
         path: fragment_info.path,
         extensions: %{code: "DEFERRED_RESOLUTION_ERROR"}
       }}
  end

  # Resolve remaining items for a streamed field
  defp resolve_streamed_field(field_info, blueprint, options) do
    # Get the full list by re-resolving without the limit
    node = restore_streamed_node(field_info.node)

    parent_data = get_parent_data(blueprint, Enum.drop(field_info.path, -1))

    sub_blueprint = build_sub_blueprint(blueprint, node, parent_data, field_info.path)

    case Resolution.run(sub_blueprint, options) do
      {:ok, resolved_blueprint} ->
        {:ok, extract_stream_result(resolved_blueprint, field_info)}

      {:error, _} = error ->
        error
    end
  rescue
    e ->
      {:error,
       %{
         message: Exception.message(e),
         path: field_info.path,
         extensions: %{code: "STREAM_RESOLUTION_ERROR"}
       }}
  end

  # Restore a deferred node for resolution
  defp restore_deferred_node(node) do
    flags = Map.delete(node.flags, :__skip_initial__)
    %{node | flags: flags}
  end

  # Restore a streamed node for full resolution
  defp restore_streamed_node(node) do
    flags = Map.delete(node.flags, :__stream_config__)
    %{node | flags: flags}
  end

  # Get parent data from the result at a given path
  defp get_parent_data(blueprint, []) do
    blueprint.result[:data] || %{}
  end

  defp get_parent_data(blueprint, path) do
    parent_path = Enum.drop(path, -1)
    get_in(blueprint.result, [:data | parent_path]) || %{}
  end

  # Build a sub-blueprint for resolving deferred/streamed content
  defp build_sub_blueprint(blueprint, node, parent_data, path) do
    # Create execution context with parent data
    execution = %{blueprint.execution | root_value: parent_data, path: path}

    # Create a minimal blueprint with just the node to resolve
    %{blueprint | execution: execution, operations: [wrap_in_operation(node, blueprint)]}
  end

  # Wrap a node in a minimal operation structure
  defp wrap_in_operation(node, blueprint) do
    %Absinthe.Blueprint.Document.Operation{
      name: "__deferred__",
      type: :query,
      selections: get_node_selections(node),
      schema_node: get_query_type(blueprint)
    }
  end

  defp get_node_selections(%{selections: selections}), do: selections
  defp get_node_selections(node), do: [node]

  defp get_query_type(blueprint) do
    Absinthe.Schema.lookup_type(blueprint.schema, :query)
  end

  # Extract result from a resolved deferred fragment
  defp extract_fragment_result(blueprint, fragment_info) do
    data = blueprint.result[:data] || %{}
    errors = blueprint.result[:errors] || []

    result = %{
      data: data,
      path: fragment_info.path,
      label: fragment_info.label
    }

    if Enum.empty?(errors) do
      result
    else
      Map.put(result, :errors, errors)
    end
  end

  # Extract remaining items from a resolved stream
  defp extract_stream_result(blueprint, field_info) do
    full_list = get_in(blueprint.result, [:data | [List.last(field_info.path)]]) || []
    remaining_items = Enum.drop(full_list, field_info.initial_count)
    errors = blueprint.result[:errors] || []

    result = %{
      items: remaining_items,
      path: field_info.path,
      label: field_info.label
    }

    if Enum.empty?(errors) do
      result
    else
      Map.put(result, :errors, errors)
    end
  end

  defp mark_as_streaming(blueprint) do
    updated_execution = Map.put(blueprint.execution, :incremental_delivery, true)
    {:ok, %{blueprint | execution: updated_execution}}
  end

  defp has_pending_operations?(streaming_context) do
    not Enum.empty?(streaming_context.deferred_fragments) or
      not Enum.empty?(streaming_context.streamed_fields)
  end

  defp get_streaming_context(blueprint) do
    get_in(blueprint.execution.context, [:__streaming__]) ||
      %{
        deferred_fragments: [],
        streamed_fields: [],
        deferred_tasks: [],
        stream_tasks: []
      }
  end

  defp put_streaming_context(blueprint, context) do
    updated_context = Map.put(blueprint.execution.context, :__streaming__, context)
    updated_execution = %{blueprint.execution | context: updated_context}
    %{blueprint | execution: updated_execution}
  end

  defp generate_operation_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp generate_task_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
