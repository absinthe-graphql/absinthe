defmodule Absinthe.Phase.FragmentPossibilitySpace do
  @moduledoc false

  alias Absinthe.{Blueprint, Type}

  def run(bp_root, _) do
    result = Blueprint.prewalk(bp_root, &handle_node(&1, bp_root.schema, bp_root.fragments))
    {:ok, result}
  end

  defp handle_node(%{schema_node: nil} = node, _, _) do
    node
  end
  defp handle_node(%Blueprint.Document.Field{} = field, schema, _) do
    possible_types = possible_types(field.schema_node, schema)
    %{field | possible_types: possible_types}
  end
  defp handle_node(%Blueprint.Document.Fragment.Inline{} = fragment, schema, _fragments) do
    possible_types = possible_types(fragment.schema_node, schema)
    %{fragment | possible_types: possible_types}
  end
  defp handle_node(%Blueprint.Document.Fragment.Spread{} = spread, schema, fragments) do
    fragments
    |> Enum.find(&(&1.name == spread.name))
    |> case do
      nil ->
        spread
      fragment ->
        %{spread | possible_types: possible_types(fragment.schema_node, schema)}
    end
  end
  defp handle_node(node, _, _) do
    node
  end

  defp possible_types(%{type: type}, schema) do
    possible_types(type, schema)
  end
  defp possible_types(type, schema) do
    schema
    |> Absinthe.Schema.lookup_type(type)
    |> case do
      %Type.Object{identifier: identifier} = object ->
        [object]

      %Type.Interface{__reference__: %{identifier: identifier}} ->
        schema.__absinthe_interface_implementors__
        |> Map.fetch!(identifier)
        |> Enum.map(&schema.__absinthe_type__/1)

      %Type.Union{types: types} ->
        types |> Enum.map(&schema.__absinthe_type__/1)

      _ ->
        []
    end
  end
end
