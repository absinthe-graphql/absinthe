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
    case validate_definition_type(definition.type, execution) do
      {:ok, schema_type, type_stack} ->
        process_variable(definition, schema_type, type_stack, execution, status)
      :error ->
        inner_type = definition.type |> unwrap
        execution = Execution.put_error(execution, :variable, inner_type.name, "Type `#{inner_type.name}': Not present in schema", at: definition.type)
        {:error, execution}
    end
  end

  defp unwrap(%{type: inner_type}), do: unwrap(inner_type)
  defp unwrap(type), do: type

  defp validate_definition_type(type, execution) do
    validate_definition_type(type, [], execution)
  end
  defp validate_definition_type(%Language.NonNullType{type: inner_type}, acc, execution) do
    validate_definition_type(inner_type, acc, execution)
  end
  defp validate_definition_type(%Language.ListType{type: inner_type}, acc, execution) do
    validate_definition_type(inner_type, [Type.List | acc], execution)
  end
  defp validate_definition_type(%Language.NamedType{name: name}, acc, execution) do
    case execution.schema.__absinthe_type__(name) do
      nil -> :error
      type -> {:ok, type, [name | acc]}
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

  defp put_variable(execution, name, variable) do
    variables = execution.variables
    |> Map.update!(:processed, &Map.put(&1, name, variable))

    %{execution | variables: variables}
  end
end
