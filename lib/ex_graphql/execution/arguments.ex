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
  @spec build(Language.Field.t, %{atom => Type.Argument.t}, Execution.t) :: {:ok, {%{atom => any}, Execution.t}} | {:error, {[binary], [binary]}, Execution.t}
  def build(ast_field, schema_arguments, execution) do
    initial = {%{}, {[], []}, execution}
    {values, {missing, invalid}, post_execution} = schema_arguments
    |> Enum.reduce(initial, &(add_argument(&1, ast_field, &2)))
    execution_to_return = report_extra_arguments(ast_field, schema_arguments |> Map.keys |> Enum.map(&to_string/1), post_execution)
    case missing ++ invalid do
      [] -> {:ok, values, execution_to_return}
      _ -> {:error, {missing, invalid}, execution_to_return}
    end
  end

  # Parse the argument value from the query document field
  @spec add_argument({atom, Type.Argument.t}, Language.Field.t, {map, {[binary], [binary]}, Execution.t}) :: {map, {[binary], [binary]}, Execution.t}
  defp add_argument({name, definition}, ast_field, acc) do
    ast_field
    |> lookup_argument(name)
    |> do_add_argument(definition, ast_field, acc)
  end

  # No argument found in the query document field
  @spec do_add_argument(Language.Argument.t | nil, Type.Argument.t, Language.Field.t, {map, {[binary], [binary]}, Execution.t}) :: {map, [binary], Execution.t}
  defp do_add_argument(nil, definition, ast_field, {values, {missing, invalid}, execution} = acc) do
    if Type.non_null?(definition.type) do
      internal_type = definition.type |> Type.unwrap
      exe = execution
      |> Execution.put_error(:argument, definition.name, &"Argument `#{&1}' (#{internal_type.name}): Not provided", at: ast_field)
      {values, {[to_string(definition.name) | missing], invalid}, exe}
    else
      acc
    end
  end
  defp do_add_argument(ast_argument, definition, _ast_field, {values, {missing, invalid}, execution} = acc) do
    value_to_coerce = ast_argument.value || execution.variables[ast_argument.name] || definition.default_value
    add_argument_value(definition.type, value_to_coerce, ast_argument, acc)
  end

  # Coerce an input value into an input type, tracking errors
  @spec add_argument_value(Type.input_t, any, Language.Argument.t, Execution.t) :: {any, Execution.t}

  # Nil value
  defp add_argument_value(input_type, nil, ast_argument, {values, {missing, invalid}, execution}) do
    if Type.non_null?(input_type) do
      internal_type = input_type |> Type.unwrap
      exe = execution
      |> Execution.put_error(:argument, ast_argument.name, &"Argument `#{&1}' (#{internal_type.name}): Not provided", at: ast_argument)
      {values, {[ast_argument.name | missing], invalid}, exe}
    else
      {
        values |> Map.put(ast_argument.name |> String.to_existing_atom, nil),
        {missing, invalid},
        execution
      }
    end
  end
  # Non-nil value
  defp add_argument_value(input_type, input_value, ast_argument, acc) do
    input_type
    |> Type.unwrap
    |> do_add_argument_value(input_value, ast_argument, acc)
  end
  # Scalar value (inside a wrapping type) found
  defp do_add_argument_value(%Type.Scalar{} = definition_type, %{value: internal_value}, ast_argument, acc) do
    do_add_argument_value(definition_type, internal_value, ast_argument, acc)
  end
  # Variable value found
  defp do_add_argument_value(definition_type, %Language.Variable{name: name}, ast_argument, {_, _, execution} = acc) do
    add_argument_value(definition_type, execution.variables[name], ast_argument, acc)
  end
  # Wrapped scalar value found
  defp do_add_argument_value(%Type.Scalar{} = type, %{value: internal_value}, ast_argument, acc) do
    do_add_argument_value(type, internal_value, ast_argument, acc)
  end
  # Bare scalar value found
  defp do_add_argument_value(%Type.Scalar{name: type_name, parse: parser} = t, internal_value, ast_argument, {values, {missing, invalid}, execution}) do
    case parser.(internal_value) do
      {:ok, coerced_value} ->
        {values |> Map.put(ast_argument.name |> String.to_existing_atom, coerced_value), {missing, invalid}, execution}
      :error ->
        {
          values,
          {missing, [ast_argument.name | invalid]},
          execution |> Execution.put_error(:argument, ast_argument.name, &"Argument `#{&1}' (#{type_name}): Invalid value provided", at: ast_argument)
        }
    end
  end
  # Enum value found
  defp do_add_argument_value(%Type.Enum{values: enum_values}, %{value: raw_value}, ast_argument, {values, {missing, invalid}, execution}) do
    case enum_values |> Map.get(raw_value) do
      nil ->
        {
          values,
          {missing, [ast_argument.name | invalid]},
          execution |> Execution.put_error(:argument, ast_argument.name, &"Argument `#{&1}' (Enum): Invalid value", at: ast_argument)
        }
      value ->
        {values |> Map.put(ast_argument.name |> String.to_existing_atom, value), {missing, invalid}, execution}
    end
  end
  # Input object value found
  defp do_add_argument_value(%Type.InputObjectType{fields: thunked_schema_fields}, %{fields: input_fields}, ast_argument, {values, {missing, invalid}, execution}) do
    schema_fields = thunked_schema_fields |> Type.unthunk
    {_, object_values, {new_missing, new_invalid}, execution_to_return} = schema_fields
    |> Enum.reduce({[ast_argument.name], %{}, {missing, invalid}, execution}, fn ({name, schema_field}, {names, acc_values, {acc_missing, acc_invalid}, acc_execution} = acc) ->
      input_field = input_fields |> Enum.find(&(&1.name == name |> to_string))
      full_name = names ++ [name |> to_string]
      case input_field do
        nil ->
          # No input value
          if Type.non_null?(schema_field.type) do
            unwrapped_type = schema_field.type |> Type.unwrap
            {
              full_name,
              acc_values,
              {[input_field.name |> to_string | acc_missing], invalid},
              acc_execution
              |> Execution.put_error(:argument, full_name |> Enum.join("."), &"Argument `#{&1}' (#{unwrapped_type.name}): Not provided", at: ast_argument)
            }
          else
            {full_name, acc_values, {acc_missing, acc_invalid}, acc_execution}
          end
        %{value: value} ->
          {result_values, {result_missing, result_invalid}, next_execution} = add_argument_value(schema_field.type, value, ast_argument, {acc_values, {acc_missing, acc_invalid}, acc_execution})
          {
            full_name,
            acc_values |> Map.put(name, value),
            {acc_missing, acc_invalid},
            acc_execution
          }
      end
    end)
    {
      values |> Map.put(ast_argument.name |> String.to_existing_atom, object_values),
      {new_missing, new_invalid},
      execution_to_return
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

end
