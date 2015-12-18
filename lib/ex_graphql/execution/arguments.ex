defmodule ExGraphQL.Execution.Arguments do

  @moduledoc """
  Handles the logic around building and validating argument values for a field.
  """

  alias ExGraphQL.Type
  alias ExGraphQL.Language

  @doc """
  Build an arguments map from the argument definitions in the schema, using the
  argument values from the query document.
  """
  @spec build(Language.Field.t, %{atom => Type.Argument.t}, Execution.t) :: {%{atom => any}, Execution.t}
  def build(ast_field, schema_arguments, execution) do
    schema_arguments
    |> Enum.reduce({%{}, execution}, &(parse(&1, ast_field, &2)))
  end

  # Parse the argument value from the query document field
  @spec parse({atom, Type.Argument.t}, Language.Field.t, {map, Execution.t}) :: {map, Execution.t}
  defp parse({name, definition} = schema_argument, ast_field, acc) do
    ast_field
    |> lookup_argument(name)
    |> do_parse(definition, acc)
  end

  # No argument found in the query document field
  @spec do_parse(Language.Argument.t | nil, Type.Argument.t, {map, Execution.t}) :: {map, Execution.t}
  defp do_parse(nil, _definition, acc) do
    acc
  end
  defp do_parse(ast_argument, definition, {values, execution}) do
    value_to_coerce = ast_argument.value || execution.variables[ast_argument.name] || definition.default_value
    {coerced_value, next_execution} = coerce(definition.type, value_to_coerce, execution)
    {
      values |> Map.put(ast_argument.name |> String.to_existing_atom, coerced_value),
      next_execution
    }
  end

  @spec lookup_argument(Language.Field.t, atom) :: Language.Argument.t | nil
  defp lookup_argument(ast_field, name) do
    argument_name = name |> to_string
    ast_field.arguments
    |> Enum.find(&(&1.name == argument_name))
  end

  # Coerce an input value into an input type, tracking errors
  @spec coerce(Type.input_t, any, Execution.t) :: {any, Execution.t}
  defp coerce(input_type, input_value, execution) do
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
  defp coerce_unwrapped(definition_type, %Language.Variable{name: name}, execution) do
    coerce(definition_type, execution.variables[name], execution)
  end
  defp coerce_unwrapped(%Type.Scalar{parse_value: parser}, bare, execution) do
    {
      bare |> to_string |> parser.(),
      execution
    }
  end

  defp coerce_unwrapped(%Type.InputObjectType{fields: thunked_schema_fields}, %{fields: input_fields}, execution) do
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
