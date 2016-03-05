defmodule Absinthe.Execution.Variables do
  # Handles the logic around building and validating variable values for an
  # execution.

  @moduledoc false

  alias Absinthe.Type
  alias Absinthe.Language
  alias Absinthe.Execution
  alias Absinthe.Schema

  defstruct raw: %{}, processed: %{}

  # Build a variables map from the variable definitions in the selected operation
  # and the variable values provided to the execution.
  @doc false
  @spec build(Execution.t) :: {%{binary => any}, Execution.t}
  def build(execution) do
    execution.selected_operation.variable_definitions
    |> Enum.reduce(execution, &build_definition/2)
  end

  def build_definition(definition, execution) do
    case validate_definition_type(definition.type, execution) do
      {:ok, schema_type} ->
        process_variable(definition, schema_type, execution)
      :error ->
        Execution.put_error(execution, :variable, definition.name, "Type `#{definition.type.name}' not present in schema", at: definition.type)
    end
  end

  defp validate_definition_type(%Absinthe.Language.ListType{type: inner_type}, execution) do
    validate_definition_type(inner_type, execution)
  end

  defp validate_definition_type(%Language.NamedType{name: name}, execution) do
    case execution.schema.__absinthe_type__(name) do
      nil -> :error
      type -> {:ok, type}
    end
  end

  defp validate_definition_type(%Language.NonNullType{type: inner_type}, execution) do
    validate_definition_type(inner_type, execution)
  end

  defp process_variable(definition, schema_type, execution) do
    raw_value = Map.get(execution.variables.raw, definition.variable.name)
    case build_variable(definition, raw_value, schema_type, execution) do
      {:ok, value, execution} ->
        put_variable(execution, definition.variable.name, value, schema_type)
      {:error, execution} ->
        execution
    end
  end

  # Non null checks here are about whether it's specified as non null via ! in
  # the document itself. It has nothing to do with whether a given argument
  # has been declared non null, that's the job of `Arguments`
  defp build_variable(%{type: %Language.NonNullType{type: inner_type}, variable: variable}, nil, _, execution) do
    execution = Execution.put_error(execution, :variable, variable.name,
      &"Variable `#{&1}' (#{inner_type.name}): Not provided",
      at: inner_type)
    {:error, execution}
  end

  defp build_variable(%{default_value: nil}, nil, schema_type, execution) do
    {:ok, nil, execution}
  end

  defp build_variable(%{default_value: %{value: value}} = definition, nil, schema_type, execution) do
    build_variable(definition, value, schema_type, execution)
  end

  defp build_variable(%{type: %Language.NonNullType{type: inner_type}} = definition, value, schema_type, execution) do
    build_variable(%{definition | type: inner_type}, value, schema_type, execution)
  end

  defp build_variable(%{type: %Language.NamedType{}, variable: var_ast}, value, %Type.Scalar{} = schema_type, execution) do
    case schema_type.parse.(value) do
      {:ok, coerced_value} ->
        {:ok, coerced_value, execution}
      :error ->
        # TODO: real error message
        execution = Execution.put_error(execution, :variable, var_ast.name, "Could not parse", at: var_ast.type)
        {:error, execution}
    end
  end

  defp build_variable(%{type: %Language.ListType{type: inner_type}, variable: var_ast} = definition, raw_values, schema_type, execution) when is_list(raw_values) do
    {values, execution} = acc_list_values(raw_values, %{definition | type: inner_type}, schema_type, [], execution)
    {:ok, values, execution}
  end

  defp build_variable(definition, values, schema_type, execution) do

    IO.puts "\n\ndefinition"
    IO.inspect definition
    IO.puts "\n\nvalue"
    IO.inspect values
    IO.puts "\n\nschem_type"
    IO.inspect schema_type
    raise "blarg"
  end

  defp acc_list_values([], _, schema_type, acc, execution), do: {:lists.reverse(acc), execution}
  defp acc_list_values([value | rest], definition, schema_type, acc, execution) do
    case build_variable(definition, value, schema_type, execution) do
      {:ok, item, execution} ->
        acc_list_values(rest, definition, schema_type, [item | acc], execution)
      {:error, execution} ->
        acc_list_values(rest, definition, schema_type, acc, execution)
        val  -> IO.inspect()
    end
  end

  defp put_variable(execution, name, value, %{name: type_name}) do
    variable = %Execution.Variable{value: value, type_name: type_name}
    variables = execution.variables
    |> Map.update!(:processed, &Map.put(&1, name, variable))

    %{execution | variables: variables}
  end
end
