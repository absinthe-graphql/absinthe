defmodule Absinthe.Phase.Document.Flatten do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.{Type, Blueprint}

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _options \\ []) do
    result = Blueprint.update_current(input, fn op ->
      flatten(op, input)
    end)
    {:ok, result}
  end

  defp flatten(%{selections: selections} = field, input) do
    fields =
      field
      |> build_fields(selections, input)
      |> Enum.map(&flatten(&1, input))

    %{field | fields: fields}
  end

  # The goal of this function is to take a set of selections and produce
  # flattened set of fields for each possible outcome of a field. Selections
  # are flattened only one level deep, because subsequent calls to `flatten/2`
  # will walk to each of them in turn and handle further flattening.
  defp build_fields(%{possible_types: parent_types}, selections, input) do
    Map.new(parent_types, fn parent_type ->
      fields =
        selections
        |> evaluate_against(parent_type)
        |> merge

      {parent_type, fields}
    end)
  end

  defp evaluate_against(selections, parent_type) do
    Enum.flat_map(selections, fn
      %{flags: %{skip: _}} -> []
      %{flags: %{invalid: _}} -> []
      # All regular fields on a field are good to go
      %Blueprint.Document.Field{} = field ->
        [field]

      %Blueprint.Document.Fragment.Inline{} = fragment ->
        if type_compatible?(parent_type, fragment) do
          # We're going from the bottom up, so if we're running into an inline
          # fragment we know its fields are already set
          fragment.fields
        else
          []
        end
    end)
  end

  defp type_compatible?(parent_type, %{possible_types: selection_types}, schema) do
    Enum.any?(selection_types, fn selection_type ->
      passes_type_condition?(selection_type, parent_type)
    end)
  end

  defp passes_type_condition?(%Type.Object{name: name}, %Type.Object{name: name}) do
    true
  end
  defp passes_type_condition?(%Type.Interface{} = condition, %Type.Object{} = type) do
    Type.Interface.member?(condition, type)
  end
  defp passes_type_condition?(%Type.Union{} = condition, %Type.Object{} = type) do
    Type.Union.member?(condition, type)
  end
  defp passes_type_condition?(_, _) do
    false
  end

  defp include?(%{flags: %{invalid: _}}), do: false
  defp include?(%{flags: %{skip: _}}), do: false
  defp include?(_), do: true

end
