defmodule ExGraphQL.Execution.Arguments do

  @moduledoc """
  Handles the logic around building and validating argument values for a field.
  """

  alias ExGraphQL.Execution
  alias ExGraphQL.Type
  alias ExGraphQL.Language

  @doc """
  Build an arguments map from the argument definitions in the schema, using the
  argument values from the query document.
  """
  @spec build(Language.Field.t, %{atom => Type.Argument.t}, Execution.t) :: {:ok, {%{atom => any}, Execution.t}} | {:error, [binary], Execution.t}
  def build(ast_field, schema_arguments, execution) do
    {values, missing, post_execution} = schema_arguments
    |> Enum.reduce({%{}, [], execution}, &(parse(&1, ast_field, &2)))
    execution_to_return = report_extra_arguments(ast_field, schema_arguments |> Map.keys |> Enum.map(&to_string/1), post_execution)
    case missing do
      [] -> {:ok, values, execution_to_return}
      _ -> {:error, missing, execution_to_return}
    end
  end

  # Parse the argument value from the query document field
  @spec parse({atom, Type.Argument.t}, Language.Field.t, {map, [binary], Execution.t}) :: {map, [binary], Execution.t}
  defp parse({name, definition}, ast_field, acc) do
    ast_field
    |> lookup_argument(name)
    |> do_parse(definition, ast_field, acc)
  end

  # No argument found in the query document field
  @spec do_parse(Language.Argument.t | nil, Type.Argument.t, Language.Field.t, {map, [binary], Execution.t}) :: {map, [binary], Execution.t}
  defp do_parse(nil, definition, ast_field, {values, missing, execution} = acc) do
    if Type.non_null?(definition.type) do
      internal_type = definition.type |> Type.unwrap
      exe = execution
      |> Execution.put_error(:argument, definition.name, &"Argument `#{&1}' (#{internal_type.name}): Not provided", at: ast_field)
      {values, [to_string(definition.name) | missing], exe}
    else
      acc
    end
  end
  defp do_parse(ast_argument, definition, _ast_field, {values, missing, execution}) do
    value_to_coerce = ast_argument.value || execution.variables[ast_argument.name] || definition.default_value
    {coerced_value, next_execution} = coerce(definition.type, value_to_coerce, execution)
    {
      values |> Map.put(ast_argument.name |> String.to_existing_atom, coerced_value),
      missing,
      next_execution
    }
  end

  # Add errors for any additional arguments not present in the schema
  @spec report_extra_arguments(Language.Field.t, [binary], Execution.t) :: Execution.t
  defp report_extra_arguments(ast_field, schema_argument_names, execution) do
    ast_field.arguments
    |> Enum.reduce(execution, fn ast_arg, acc ->
      if Enum.member?(schema_argument_names, ast_arg.name) do
        acc
      else
        execution
        |> Execution.put_error(:argument, ast_arg.name, "Not present in schema", at: ast_arg)
      end
    end)
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
