defmodule ExGraphQL.Execution.Arguments do

  alias ExGraphQL.Type
  alias ExGraphQL.Language

  @spec build([Language.Argument.t], [Type.Argument.t], Execution.t) :: {%{atom => any}, Execution.t}
  def build(ast_arguments, schema_arguments, %{variables: variables} = execution) do
    result = {%{}, execution}
    schema_arguments
    |> Enum.reduce(result, fn ({name, definition}, {values, exe} = acc) ->
      ast_arg = ast_arguments |> Enum.find(&(&1.name == name |> to_string))
      if ast_arg do
        value_to_coerce = ast_arg.value || variables[ast_arg.name] || definition.default_value
        {coerced_value, next_execution} = coerce(definition.type, value_to_coerce, exe)
        {
          values |> Map.put(name, coerced_value),
          next_execution
        }
      else
        acc
      end
    end)
  end

  @doc "Coerce an input value into an input type, tracking errors"
  @spec coerce(Type.input_t, any, Execution.t) :: {any, Execution.t}
  def coerce(input_type, input_value, execution) do
    input_type
    |> Type.unwrap
    |> coerce_unwrapped(input_value, execution)
  end

  defp coerce_unwrapped(%Type.Scalar{parse_value: parser}, %{value: internal_value}, execution) do
    {
      internal_value |> parser.(),
      execution
    }
  end
  defp coerce_unwrapped(definition_type, %Language.Variable{name: name}, %{variables: variables} = execution) do
    variable_value = variables |> Map.get(name)
    coerce(definition_type, variable_value, execution)
  end
  defp coerce_unwrapped(%Type.Scalar{parse_value: parser}, bare, execution) do
    {
      bare |> to_string |> parser.(),
      execution
    }
  end

  defp coerce_unwrapped(%Type.InputObjectType{fields: thunked_schema_fields}, %{fields: input_fields}, %{variables: variables} = execution) do
    schema_fields = thunked_schema_fields |> Type.unthunk
    result = {%{}, execution}
    schema_fields
    |> Enum.reduce(result, fn ({name, schema_field}, {values, exe} = acc) ->
      input_field = input_fields |> Enum.find(&(&1.name == name |> to_string))
      case input_field do
        nil ->
          acc
        %{value: value} ->
          {coerced_value, next_exe} = coerce(schema_field.type, value, exe)
          {
            values |> Map.put(name, coerced_value),
            next_exe
          }
      end
    end)
  end
  defp coerce_unwrapped(%Type.Enum{values: enum_values}, %{value: raw_value}, execution) do
    {
      enum_values |> Map.get(raw_value),
      execution
    }
  end

end
