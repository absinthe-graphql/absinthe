defmodule ExGraphQL.Execution.Literal do

  alias ExGraphQL.Type
  alias ExGraphQL.Language

  def coerce(input_type, input_value, variables) do
    input_type
    |> Type.unwrap
    |> coerce_unwrapped(input_value, variables)
  end

  defp coerce_unwrapped(%Type.Scalar{} = scalar, %{value: internal_value}, _variables) do
    internal_value
    |> scalar.parse_value.()
  end
  defp coerce_unwrapped(definition_type, %Language.Variable{name: name}, variables) do
    variable_value = variables |> Map.get(name)
    coerce(definition_type, variable_value, variables)
  end
  defp coerce_unwrapped(%Type.Scalar{} = scalar, bare, _variables) do
    bare
    |> to_string
    |> scalar.parse_value.()
  end

  defp coerce_unwrapped(%Type.InputObjectType{fields: thunked_schema_fields}, %{fields: input_fields}, variables) do
    schema_fields = thunked_schema_fields |> Type.unthunk
    input_fields
    |> Enum.reduce(%{}, fn (%{name: name, value: input_value}, acc) ->
      case schema_fields |> Map.get(name |> String.to_existing_atom) do
        nil -> acc
        field -> acc |> Map.put(name |> to_string, coerce(field.type, input_value, variables))
      end
    end)
  end
  defp coerce_unwrapped(%Type.Enum{values: enum_values}, %{value: raw_value}, _variables) do
    enum_values |> Map.get(raw_value)
  end

end
