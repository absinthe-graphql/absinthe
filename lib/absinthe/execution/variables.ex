defmodule Absinthe.Execution.Variables do
  # Handles the logic around building and validating variable values for an
  # execution.

  @moduledoc false

  alias Absinthe.Type
  alias Absinthe.Language
  alias Absinthe.Execution
  alias Absinthe.Schema

  # Build a variables map from the variable definitions in the selected operation
  # and the variable values provided to the execution.
  @doc false
  @spec build(Execution.t) :: {%{binary => any}, Execution.t}
  def build(execution) do
    execution.selected_operation.variable_definitions
    |> Enum.reduce({%{}, execution |> normalize_keys}, &parse/2)
  end

  # Normalize the variable keys to binaries
  @spec normalize_keys(Execution.t) :: Execution.t
  defp normalize_keys(execution) do
    %{execution | variables: execution.variables |> Execution.stringify_keys}
  end

  # Parse a definition and add values/errors
  @spec parse(Language.VariableDefinition.t, {map, Execution.t}) :: {map, Execution.t}
  defp parse(definition, {_, execution} = acc) do
    name = definition.variable.name
    ast_type = definition.type |> Language.unwrap
    schema_type = Schema.type_from_ast(execution.schema, definition.type)
    do_parse(name, definition, ast_type, schema_type, acc)
  end

  # No schema type was found
  @spec do_parse(atom, Language.VariableDefinition.t, Language.NamedType.t, Type.input_t, {map, Execution.t}) :: {map, Execution.t}
  defp do_parse(name, _definition, ast_type, nil, {values, execution}) do
    exe = execution
    |> Execution.put_error(:variable, name, "Type (#{ast_type.name}) not present in schema", at: ast_type )
    {values, exe}
  end
  defp do_parse(name, definition, ast_type, schema_type, {_, execution} = acc) do
    default_value = default(definition.default_value)
    provided_value = execution.variables |> Map.get(name |> to_string)
    value = provided_value || default_value
    case Type.valid_input?(schema_type, value) do
      true ->
        valid(name, value, schema_type, acc)
      false ->
        invalid(name, value, ast_type, schema_type, acc)
    end
  end

  # Accumulate the value for a valid variable
  @spec valid(atom, any, Type.input_t, {map, Execution.t}) :: {map, Execution.t}
  defp valid(name, value, schema_type, {values, execution}) do
    {
      values |> Map.put(to_string(name), coerce(value, schema_type)),
      execution
    }
  end

  # Accumulate an error for an invalid variable
  @spec invalid(atom, any, Language.NamedType.t, Type.input_t, {map, Execution.t}) :: {map, Execution.t}
  defp invalid(name, value, ast_type, _schema_type, {values, execution}) do
    exe = execution
    |> Execution.put_error(:variable, name, error_message(ast_type, value), at: ast_type)
    {values, exe}
  end

  # Define the error message for an invalid variable
  @spec error_message(Language.NamedType.t, any) :: (binary -> binary)
  defp error_message(ast_type, nil) do
    &"Variable `#{&1}' (#{ast_type.name}): Not provided"
  end
  defp error_message(ast_type, _value) do
    &"Variable `#{&1}' (#{ast_type.name}): Invalid value"
  end

  # Coerce a value or default provided for a variable so it is suitable for
  # the defined type
  @spec coerce(any, Type.input_t) :: any
  defp coerce(nil, _schema_type) do
    nil
  end
  defp coerce(value, schema_type) do
    %{parse: parser} = schema_type |> Type.unwrap
    case parser.(value) do
      {:ok, coerced} -> coerced
      :error -> nil
    end
  end

  # Extract the default value, if any
  @spec default(Absinthe.Language.value_t) :: any
  defp default(%{value: value}), do: value
  defp default(_), do: nil

end
