defmodule Absinthe.Phase.Document.Flatten do
  @moduledoc """
  Flatten inline fragment contents and named fragments (via fragment spreads)
  from operation and field selections into their fields list. Resulting fields
  are tagged with the source fragment type conditions.

  Note that no field merging occurs in this phase and that validation should
  occur before it is run (to, eg, prevent circular fragments).
  """

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _) do
    # TODO: Pass a Map of the fragments by name
    {result, _} = Blueprint.postwalk(input, input.fragments, &flatten/2)
    {:ok, result}
  end

  defp flatten(%{selections: selections, fields: _} = node, fragments) do
    fields = Enum.map(selections, &selection_to_fields(&1, fragments))
    |> List.flatten
    |> inherit_type_condition(node)
    {
      %{node | fields: fields},
      fragments
    }
  end
  defp flatten(node, fragments) do
    {node, fragments}
  end

  @spec selection_to_fields(Blueprint.Document.selection_t, [Blueprint.Document.Fragment.Named.t]) :: [Blueprint.Document.Field.t]
  defp selection_to_fields(%Blueprint.Document.Field{} = node, _) do
    [node]
  end
  defp selection_to_fields(%Blueprint.Document.Fragment.Inline{} = node, fragments) do
    case node.fields do
      [] ->
        node.selections
        |> Enum.map(&selection_to_fields(&1, fragments))
        |> List.flatten
        |> inherit_type_condition(node)
      _ ->
        node.fields
    end
  end
  defp selection_to_fields(%Blueprint.Document.Fragment.Named{} = node, fragments) do
    case node.fields do
      [] ->
        node.selections
        |> Enum.map(&selection_to_fields(&1, fragments))
        |> List.flatten
        |> inherit_type_condition(node)
      _ ->
        node.fields
    end
  end
  defp selection_to_fields(%Blueprint.Document.Fragment.Spread{} = node, fragments) do
    named = fragments |> Enum.find(&(&1.name == node.name))
    selection_to_fields(named, fragments)
  end

  @spec inherit_type_condition([Blueprint.Document.Field.t], Blueprint.Document.t) :: [Blueprint.Document.t]
  defp inherit_type_condition(fields, %{type_condition: nil}) do
    fields
  end
  defp inherit_type_condition(fields, %{type_condition: condition}) do
    fields
    |> Enum.map(fn field ->
      update_in(field.type_conditions, &MapSet.to_list(MapSet.new([condition | &1])))
    end)
  end
  defp inherit_type_condition(fields, _) do
    fields
  end

end
