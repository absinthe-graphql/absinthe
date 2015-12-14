defmodule ExGraphQL.Execution.LiteralInput do

  alias ExGraphQL.Type

  def from_arguments(ast_arguments, schema_arguments, variables) do
    schema_arguments
    |> Enum.reduce(%{}, fn ({name, definition}, acc) ->
      ast_arg = ast_arguments |> Enum.find(&(String.to_atom(&1.name) == name))
      if ast_arg do
        ast_value = if ast_arg.value do
          coerce(definition.type, ast_arg.value)
        else
          nil
        end
        variable_value = variables[ast_arg.name]
        default_value = definition.default_value
        acc
        |> Map.put(name |> to_string, ast_value || variable_value || default_value)
      else
        acc
      end
    end)
  end

  def coerce(input_type, input_value) do
    input_type
    |> Type.unwrap
    |> coerce_unwrapped(input_value)
  end

  defp coerce_unwrapped(%{__struct__: Type.Scalar} = scalar, %{value: internal_value}) do
    internal_value
    |> scalar.parse_value.()
  end
  defp coerce_unwrapped(%{__struct__: Type.Scalar} = scalar, bare) do
    bare
    |> to_string
    |> scalar.parse_value.()
  end

  defp coerce_unwrapped(%{__struct__: Type.InputObjectType, fields: thunked_schema_fields}, %{fields: input_fields}) do
    schema_fields = thunked_schema_fields |> Type.unthunk
    input_fields
    |> Enum.reduce(%{}, fn (%{name: name, value: input_value}, acc) ->
      case schema_fields |> Map.get(name |> String.to_existing_atom) do
        nil -> acc
        field -> acc |> Map.put(name |> to_string, coerce(field.type, input_value))
      end
    end)
  end
  defp coerce_unwrapped(%{__struct__: Type.Enum, values: enum_values}, %{value: raw_value}) do
    enum_values |> Map.get(raw_value)
  end

end
