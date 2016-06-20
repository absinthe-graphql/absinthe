defmodule Absinthe.Execution.Variables do
  # Handles the logic around building and validating variable values for an
  # execution.

  @moduledoc false

  alias Absinthe.Type
  alias Absinthe.Language
  alias Absinthe.Execution

  defstruct raw: %{}, processed: %{}

  # Build a variables map from the variable definitions in the selected operation
  # and the variable values provided to the execution.
  @doc false
  @spec build(Execution.t) :: {%{binary => any}, Execution.t}
  def build(execution) do
    execution.selected_operation.variable_definitions
    |> Enum.reduce({:ok, execution}, &build_definition/2)
  end

  def build_definition(definition, {status, execution}) do
    with :ok <- validate_definition_uniqueness(definition, execution),
         {:ok, schema_type, type_stack} <- validate_definition_type(definition, execution) do
      process_variable(definition, schema_type, type_stack, execution, status)
    end
  end

  defp unwrap(%{type: inner_type}), do: unwrap(inner_type)
  defp unwrap(type), do: type

  # Validate that a variable is not defined more than once for the operation
  @spec validate_definition_uniqueness(Language.VariableDefinition.t, Execution.t) :: :ok | {:error, Execution.t}
  defp validate_definition_uniqueness(definition, execution) do
    case Map.get(execution.variables.processed, definition.variable.name) do
      nil ->
        :ok
      _ ->
        execution = Execution.put_error(execution, :variable, definition.variable.name, "Defined more than once", at: definition.type)
        {:error, execution}
    end
  end

  # Validate that the variable type is defined in the schema
  @spec validate_definition_type(Language.VariableDefinition.t, Execution.t) :: :ok | {:error, Execution.t}
  defp validate_definition_type(definition, execution) do
    do_validate_definition_type(definition, definition.type, [], execution)
  end

  defp do_validate_definition_type(definition, %Language.NonNullType{type: inner_type}, acc, execution) do
    do_validate_definition_type(definition, inner_type, acc, execution)
  end
  defp do_validate_definition_type(definition, %Language.ListType{type: inner_type}, acc, execution) do
    do_validate_definition_type(definition, inner_type, [Type.List | acc], execution)
  end
  defp do_validate_definition_type(definition, %Language.NamedType{name: name}, acc, execution) do
    case execution.schema.__absinthe_type__(name) do
      nil ->
        inner_type = definition.type |> unwrap
        execution = Execution.put_error(execution, :variable, inner_type.name, "Type `#{inner_type.name}': Not present in schema", at: definition.type)
        {:error, execution}
      type ->
        {:ok, type, [name | acc]}
    end
  end

  defp process_variable(definition, schema_type, type_stack, execution, status) do
    case Execution.Variable.build(definition, schema_type, type_stack, execution) do
      {:ok, variable, execution} ->
        {status, put_variable(execution, definition.variable.name, variable)}
      error ->
        error
    end
  end

  defp put_variable(execution, _, %{value: nil}) do
    execution
  end
  defp put_variable(execution, name, variable) do
    variables = execution.variables
    |> Map.update!(:processed, &Map.put(&1, name, variable))

    %{execution | variables: variables}
  end
end
