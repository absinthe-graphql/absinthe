defmodule ExGraphQL.Execution.Arguments do

  @moduledoc """
  Handles the logic around building and validating argument values for a field.
  """

  alias ExGraphQL.Validation
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
    if Validation.RequiredInput.required?(definition) do
      internal_type = definition.type |> Type.unwrap
      exe = execution
      |> Execution.put_error(:argument, definition.name, &"Argument `#{&1}' (#{internal_type.name}): Not provided", at: ast_field)
      {values, {[to_string(definition.name) | missing], invalid}, exe}
    else
      acc
    end
  end
  defp do_add_argument(ast_argument, definition, _ast_field, {_, _, execution} = acc) do
    value_to_coerce = ast_argument.value || execution.variables[ast_argument.name] || definition.default_value
    add_argument_value(definition.type, value_to_coerce, ast_argument, [ast_argument.name], acc)
  end

  # Coerce an input value into an input type, tracking errors
  @spec add_argument_value(Type.input_t, any, Language.Argument.t, [binary], Execution.t) :: {any, Execution.t}

  # Nil value
  defp add_argument_value(input_type, nil, ast_argument, [value_name|_] = full_value_name, {values, {missing, invalid}, execution}) do

    if Validation.RequiredInput.required?(input_type) do
      name_to_report = full_value_name |> dotted_name
      internal_type = input_type |> Type.unwrap
      exe = execution
      |> Execution.put_error(:argument, name_to_report, &"Argument `#{&1}' (#{internal_type.name}): Not provided", at: ast_argument)
      {values, {[name_to_report | missing], invalid}, exe}
    else
      {
        values |> Map.put(value_name |> String.to_existing_atom, nil),
        {missing, invalid},
        execution
      }
    end
  end
  # Non-nil value
  defp add_argument_value(input_type, input_value, ast_argument, names, acc) do
    input_type
    |> Type.unwrap
    |> do_add_argument_value(input_value, ast_argument, names, acc)
  end
  # Scalar value (inside a wrapping type) found
  defp do_add_argument_value(%Type.Scalar{} = definition_type, %{value: internal_value}, ast_argument, names, acc) do
    do_add_argument_value(definition_type, internal_value, ast_argument, names, acc)
  end
  # Variable value found
  defp do_add_argument_value(definition_type, %Language.Variable{name: name}, ast_argument, names, {_, _, execution} = acc) do
    add_argument_value(definition_type, execution.variables[name], ast_argument, names, acc)
  end
  # Wrapped scalar value found
  defp do_add_argument_value(%Type.Scalar{} = type, %{value: internal_value}, ast_argument, names, acc) do
    do_add_argument_value(type, internal_value, ast_argument, names, acc)
  end
  # Bare scalar value found
  defp do_add_argument_value(%Type.Scalar{name: type_name, parse: parser}, internal_value, ast_argument, [value_name | _] = full_value_name, {values, {missing, invalid}, execution}) do
    case parser.(internal_value) do
      {:ok, coerced_value} ->
        {values |> Map.put(value_name |> String.to_existing_atom, coerced_value), {missing, invalid}, execution}
      :error ->
        name_to_report = full_value_name |> dotted_name
        {
          values,
          {missing, [name_to_report | invalid]},
          execution |> Execution.put_error(:argument, name_to_report, &"Argument `#{&1}' (#{type_name}): Invalid value provided", at: ast_argument)
        }
    end
  end
  # Enum value found
  defp do_add_argument_value(%Type.Enum{values: enum_values}, %{value: raw_value}, ast_argument, [value_name | _] = full_value_name, {values, {missing, invalid}, execution}) do
    case enum_values |> Map.get(raw_value) do
      nil ->
        name_to_report = full_value_name |> dotted_name
        {
          values,
          {missing, [name_to_report | invalid]},
          execution |> Execution.put_error(:argument, name_to_report, &"Argument `#{&1}' (Enum): Invalid value", at: ast_argument)
        }
      value ->
        {values |> Map.put(value_name |> String.to_existing_atom, value), {missing, invalid}, execution}
    end
  end
  # Input object value found
  defp do_add_argument_value(%Type.InputObjectType{fields: thunked_schema_fields}, %{fields: input_fields}, ast_argument, [value_name | _] = names, {values, {missing, invalid}, execution}) do
    schema_fields = thunked_schema_fields |> Type.unthunk
    {_, object_values, {new_missing, new_invalid}, execution_to_return} = schema_fields
    |> Enum.reduce({names, %{}, {missing, invalid}, execution}, fn ({name, schema_field}, {acc_value_name, acc_values, {acc_missing, acc_invalid}, acc_execution}) ->
      input_field = input_fields |> Enum.find(&(&1.name == name |> to_string))
      full_value_name = [name |> to_string | acc_value_name]
      case input_field do
        nil ->
          # No input value
          if Validation.RequiredInput.required?(schema_field.type) do
            name_to_report = full_value_name |> dotted_name
            unwrapped_type = schema_field.type |> Type.unwrap
            {
              acc_value_name,
              acc_values,
              {[name_to_report | acc_missing], invalid},
              acc_execution
              |> Execution.put_error(:argument, name_to_report, &"Argument `#{&1}' (#{unwrapped_type.name}): Not provided", at: ast_argument)
            }
          else
            {acc_value_name, acc_values, {acc_missing, acc_invalid}, acc_execution}
          end
        %{value: value} ->
          {result_values, {result_missing, result_invalid}, next_execution} = add_argument_value(schema_field.type, value, ast_argument, full_value_name, {acc_values, {acc_missing, acc_invalid}, acc_execution})
          {
            acc_value_name,
            result_values,
            {result_missing, result_invalid},
            next_execution
          }
      end
    end)
    {
      values |> Map.put(value_name |> String.to_existing_atom, object_values),
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

  @spec dotted_name([binary]) :: binary
  defp dotted_name(names) do
    names |> Enum.reverse |> Enum.join(".")
  end

end
