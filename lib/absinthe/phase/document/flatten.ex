defmodule Absinthe.Phase.Document.Flatten do
  @moduledoc false

  # Flatten inline fragment contents and named fragments (via fragment spreads)
  # from operation and field selections into their fields list. Resulting fields
  # are tagged with the source fragment type conditions.
  #
  # Note that no field merging occurs in this phase and that validation should
  # occur before it is run (to, eg, prevent circular fragments).


  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _options \\ []) do
    fragments = for fragment <- input.fragments do
      process(fragment, input.fragments)
    end
    input = %{input | fragments: fragments}
    result = input
    |> Blueprint.update_current(&process(&1, input.fragments))

    {:ok, result}
  end

  defp process(%{selections: selections} = node, fragments) do
    fields = Enum.flat_map(selections, &selection_to_fields(&1, fragments))
    |> inherit_type_condition(node)
    put_flag(%{node | fields: fields}, :flat)
  end

  @spec selection_to_fields(Blueprint.Document.selection_t, [Blueprint.Document.Fragment.Named.t]) :: [Blueprint.Document.Field.t]
  defp selection_to_fields(%Blueprint.Document.Field{} = node, fragments) do
    if include?(node) do
      [
        process(node, fragments)
      ]
    else
      []
    end
  end
  defp selection_to_fields(%Blueprint.Document.Fragment.Inline{} = node, fragments) do
    if include?(node) do
      case node.fields do
        [] ->
          node.selections
          |> Enum.map(&selection_to_fields(&1, fragments))
          |> List.flatten
          |> inherit_type_condition(node)
          |> Enum.map(&process(&1, fragments))
        _ ->
          node.fields
      end
    else
      []
    end
  end
  defp selection_to_fields(%Blueprint.Document.Fragment.Named{} = node, fragments) do
    if include?(node) do
      case node.fields do
        [] ->
          node.selections
          |> Enum.map(&selection_to_fields(&1, fragments))
          |> List.flatten
          |> inherit_type_condition(node)
          |> Enum.map(&process(&1, fragments))
        _ ->
          node.fields
      end
    else
      []
    end
  end

   defp selection_to_fields(%Blueprint.Document.Fragment.Spread{} = node, fragments) do
     if include?(node) do
       named = fragments |> Enum.find(&(&1.name == node.name))
       selection_to_fields(named, fragments)
     else
       []
     end
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

  defp include?(%{flags: %{invalid: _}}), do: false
  defp include?(%{flags: %{skip: _}}), do: false
  defp include?(_), do: true

end
