defmodule Absinthe.Phase.Document.Execution.StreamingResolution do
  @moduledoc """
  Resolution phase with support for @defer directive.
  Replaces standard resolution when incremental delivery is enabled.

  Strategy: run standard resolution (resolves everything), then store defer
  metadata in the streaming context. The transport layer (plug) splits the
  final result into initial/incremental payloads after the Result phase runs.
  """

  use Absinthe.Phase
  alias Absinthe.{Blueprint, Phase}
  alias Absinthe.Phase.Document.Execution.Resolution

  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(blueprint, options \\ []) do
    defer_info = collect_defer_info(blueprint)

    if Enum.empty?(defer_info) do
      Resolution.run(blueprint, options)
    else
      # Run standard resolution — resolves everything including deferred fields.
      # The result split happens later in the transport layer.
      case Resolution.run(blueprint, options) do
        {:ok, blueprint} ->
          streaming_context = %{
            defer_info: defer_info,
            operation_id: generate_operation_id(),
            # Backwards-compat keys expected by Absinthe.Incremental.*
            deferred_fragments: defer_info,
            streamed_fields: [],
            deferred_tasks: [],
            stream_tasks: []
          }

          updated_context = Map.put(blueprint.execution.context, :__streaming__, streaming_context)
          updated_execution = %{blueprint.execution | context: updated_context}
          updated_execution = Map.put(updated_execution, :incremental_delivery, true)

          {:ok, %{blueprint | execution: updated_execution}}

        error ->
          error
      end
    end
  end

  # Walk operations to find @defer fragments with their parent field path.
  defp collect_defer_info(blueprint) do
    blueprint.operations
    |> Enum.flat_map(fn op ->
      walk_selections(op.selections, [], blueprint)
    end)
  end

  defp walk_selections(selections, parent_path, blueprint) when is_list(selections) do
    Enum.flat_map(selections, fn sel -> walk_selection(sel, parent_path, blueprint) end)
  end
  defp walk_selections(_, _, _blueprint), do: []

  defp walk_selection(%Blueprint.Document.Field{name: name, selections: sels}, parent_path, blueprint) do
    walk_selections(sels, parent_path ++ [name], blueprint)
  end

  defp walk_selection(
         %Blueprint.Document.Fragment.Inline{
           flags: %{defer: %{enabled: true} = config},
           selections: sels
         },
         parent_path,
         blueprint
       ) do
    field_names = Enum.flat_map(sels, &extract_field_names/1)

    [
      %{label: config[:label], field_names: field_names, parent_path: parent_path}
      | walk_selections(sels, parent_path, blueprint)
    ]
  end

  defp walk_selection(%Blueprint.Document.Fragment.Inline{selections: sels}, parent_path, blueprint) do
    walk_selections(sels, parent_path, blueprint)
  end

  # Handle Fragment.Spread — resolve the named fragment and check for @defer
  # on both the spread itself and nested inline fragments within the fragment.
  defp walk_selection(
         %Blueprint.Document.Fragment.Spread{name: name, flags: flags},
         parent_path,
         blueprint
       ) do
    case Blueprint.fragment(blueprint, name) do
      nil ->
        []

      %{selections: sels} ->
        spread_defers =
          case flags do
            %{defer: %{enabled: true} = config} ->
              field_names = Enum.flat_map(sels, &extract_field_names/1)
              [%{label: config[:label], field_names: field_names, parent_path: parent_path}]

            _ ->
              []
          end

        spread_defers ++ walk_selections(sels, parent_path, blueprint)
    end
  end

  defp walk_selection(_, _parent_path, _blueprint), do: []

  defp extract_field_names(%Blueprint.Document.Field{name: name}), do: [name]
  defp extract_field_names(%{selections: sels}) when is_list(sels) do
    Enum.flat_map(sels, &extract_field_names/1)
  end
  defp extract_field_names(_), do: []

  defp generate_operation_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
