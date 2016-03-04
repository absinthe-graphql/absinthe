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
        build_variable(definition, schema_type, execution)
      :error ->
        Execution.put_error(execution, :variable, definition.name, "Type `#{definition.type.name}' not present in schema", at: definition.type)
    end
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

  defp build_variable(definition, schema_type, execution) do
    value = Map.get(execution.variables.raw, definition.variable.name)
    do_build_variable(definition, value, schema_type, execution)
  end

  # Non null checks here are about whether it's specified as non null via ! in
  # the document itself. It has nothing to do with whether a given argument
  # has been declared non null, that's the job of `Arguments`
  defp do_build_variable(%{type: %Language.NonNullType{type: inner_type}, variable: variable}, nil, _, execution) do
    Execution.put_error(execution, :variable, variable.name,
      &"Variable `#{&1}' (#{inner_type.name}): Not provided",
      at: inner_type)
  end

  defp do_build_variable(%{default_value: nil}, nil, schema_type, execution) do
    execution
  end

  defp do_build_variable(%{default_value: %{value: value}, variable: var_ast} = def, nil, schema_type, execution) do
    case Execution.Variable.build(value, schema_type) do
      {:ok, var} ->
        add_variable(execution, var_ast.name, var)
      {:error, reason} ->
        Execution.put_error(execution, :variable, var_ast.name, reason, at: var_ast.type)
    end
  end

  defp do_build_variable(%{type: %Language.NonNullType{type: inner_type}} = definition, value, schema_type, execution) do
    definition = %{definition | type: inner_type}
    do_build_variable(definition, value, schema_type, execution)
  end

  defp do_build_variable(%{type: %Language.NamedType{}, variable: var_ast}, value, schema_type, execution) do
    case Execution.Variable.build(value, schema_type) do
      {:ok, var} ->
        add_variable(execution, var_ast.name, var)
      {:error, reason} ->
        Execution.put_error(execution, :variable, var_ast.name, reason, at: var_ast.type)
    end
  end

  defp add_variable(execution, name, var) do
    variables = execution.variables
    |> Map.update!(:processed, &Map.put(&1, name, var))

    %{execution | variables: variables}
  end

  defp do_build([], acc, execution), do: {acc, execution}
  defp do_build([definition | rest], acc, execution) do
    case build_value(definition, execution) do
      {:ok, value} ->
        do_build(rest, Map.put(acc, definition.name, value), execution)
      {:error, reason} ->
        execution = Execution.put_error(execution, :variable, definition.name, "Type (#{definition.type.name}) not present in schema", at: definition.type)
        do_build(rest, acc, execution)
    end
  end

  defp build_value(%{type: type, variable: variable}, execution) do
    value = execution.variables |> Map.get(variable.name)
    do_build_value(type, variable)
  end

  defp do_build_value(%Language.NonNullType{type: inner_type}, nil) do

  end
end
