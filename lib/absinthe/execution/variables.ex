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
    |> Enum.reduce(execution, &build_definition/2)
  end

  def build_definition(definition, execution) do
    case validate_definition_type(definition.type, execution) do
      {:ok, schema_type, type_stack} ->
        process_variable(definition, schema_type, type_stack, execution)
      :error ->
        inner_type = definition.type |> unwrap
        inner_type |> IO.inspect
        Execution.put_error(execution, :variable, inner_type.name, "Type `#{inner_type.name}' not present in schema", at: definition.type)
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

  defp process_variable(definition, schema_type, type_stack, execution) do
    raw_value = Map.get(execution.variables.raw, definition.variable.name)
    case build_variable(definition, raw_value, schema_type, execution) do
      {:ok, value, execution} ->
        put_variable(execution, definition.variable.name, value, type_stack)
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

  defp build_variable(%{default_value: nil}, nil, _schema_type, execution) do
    {:ok, nil, execution}
  end

  defp build_variable(%{default_value: %{value: value}} = definition, nil, schema_type, execution) do
    build_variable(definition, value, schema_type, execution)
  end

  defp build_variable(%{type: %Language.NonNullType{type: inner_type}} = definition, value, schema_type, execution) do
    build_variable(%{definition | type: inner_type}, value, schema_type, execution)
  end

  defp build_variable(%{type: %Language.ListType{type: inner_type}} = definition, raw_values, schema_type, execution) when is_list(raw_values) do
    {values, execution} = acc_list_values(raw_values, %{definition | type: inner_type}, schema_type, [], execution)
    {:ok, values, execution}
  end

  defp build_variable(%{variable: _}, values, %Type.InputObject{fields: schema_fields}, execution) when is_map(values) do
    {values, execution} = acc_map_values(Map.to_list(values), schema_fields, %{}, execution)
    {:ok, values, execution}
  end

  defp build_variable(%{variable: var_ast}, value, %Type.Enum{} = enum, execution) do
    case Type.Enum.parse(enum, value) do
      {:ok, value} ->
        {:ok, value, execution}

      :error ->
        execution = Execution.put_error(execution, :variable, var_ast.name, &"Argument `#{&1}' (#{enum.name}): Invalid value provided", at: var_ast)
        {:error, execution}
    end
  end

  defp build_variable(%{variable: var_ast}, value, %Type.Scalar{} = schema_type, execution) do
    case schema_type.parse.(value) do
      {:ok, coerced_value} ->
        {:ok, coerced_value, execution}
      :error ->
        # TODO: real error message
        execution = Execution.put_error(execution, :variable, var_ast.name, &"Argument `#{&1}' (#{schema_type.name}): Invalid value provided", at: var_ast)
        {:error, execution}
    end
  end

  defp build_variable(%{variable: var_ast} = definition, values, schema_type, execution) do
    execution = Execution.put_error(execution, :variable, var_ast.name, &"Argument `#{&1}' (#{schema_type.name}): Invalid value provided", at: var_ast)
    {:error, execution}
  end

  defp acc_list_values([], _, _, acc, execution), do: {:lists.reverse(acc), execution}
  defp acc_list_values([value | rest], definition, schema_type, acc, execution) do
    case build_variable(definition, value, schema_type, execution) do
      {:ok, item, execution} ->
        acc_list_values(rest, definition, schema_type, [item | acc], execution)
      {:error, execution} ->
        {:error, execution}
    end
  end

  # So this sorta sucks.
  # Input objects create their own world where it's simply bare elixir
  # values and schema types, whereas previously it was AST values and schema types
  # There's a fair bit of duplication between what's here, what's earlier in the module,
  # and what exists over in Arguments.ex
  # I don't necessarily think that the duplication is ipso facto bad, but each individual
  # use case should at least live in its own module that gives it some more semantic value

  defp build_map_value(value, %Type.Field{type: inner_type}, execution) do
    build_map_value(value, inner_type, execution)
  end
  defp build_map_value(nil, %Type.NonNull{of_type: _inner_type}, execution) do
    # TODO: add error
    raise "why am I here?"
    {:error, execution}
  end
  defp build_map_value(value, %Type.NonNull{of_type: inner_type}, execution) do
    build_map_value(value, inner_type, execution)
  end
  defp build_map_value(value, %Type.Scalar{parse: parser}, execution) do
    case parser.(value) do
      {:ok, coerced_value} ->
        {:ok, coerced_value, execution}
      :error ->
        {:error, execution}
    end
  end
  defp build_map_value(value, type, execution) when is_atom(type) do
    real_type = execution.schema.__absinthe_type__(type)
    build_map_value(value, real_type, execution)
  end

  defp acc_map_values([], remaining_fields, acc, execution) do
    {acc, execution} = Enum.reduce(remaining_fields, {acc, execution}, fn
      {name, %{type: %Type.NonNull{of_type: inner_type}, deprecation: nil}}, {acc, exec} ->
        exec = Execution.put_error(exec, :variable, name,
          &"Variable `#{&1}' (#{name}): Not provided",
          at: nil)
        {acc, exec}

      {_, %{default_value: nil}}, {acc, meta} ->
        {acc, meta}

      {name, %{default_value: default}}, {acc, meta} ->
        case Map.get(acc, name) do
          nil -> {Map.put(acc, name, default), meta}
          _ -> {acc, meta}
        end
    end)
    {acc, execution}
  end
  defp acc_map_values([{_, nil} | rest], schema_fields, acc, execution) do
    acc_map_values(rest, schema_fields, acc, execution)
  end
  defp acc_map_values([{key, raw_value} | rest], schema_fields, acc, execution) do
    case pop_field(schema_fields, key) do
      {name, schema_field, schema_fields} ->
        case build_map_value(raw_value, schema_field, execution) do
          {:ok, value, execution} ->
            acc_map_values(rest, schema_fields, Map.put(acc, name, value), execution)

          {:error, execution} ->
            acc_map_values(rest, schema_fields, acc, execution)
        end

      :error ->
        # Todo: register field as unnecssary
        acc_map_values(rest, schema_fields, acc, execution)
    end
  end

  # Given a document argument, pop the relevant schema argument
  # The reason for popping the arg is that it's an easy way to prevent using
  # the same argument name twice.
  defp pop_field(schema_arguments, name) do
    name = String.to_existing_atom(name)

    case Map.pop(schema_arguments, name) do
      {nil, _} -> :error
      {val, args} -> {name, val, args}
    end
  rescue
    ArgumentError -> :error
  end

  defp put_variable(execution, name, value, type_stack) do
    variable = %Execution.Variable{value: value, type_stack: type_stack}
    variables = execution.variables
    |> Map.update!(:processed, &Map.put(&1, name, variable))

    %{execution | variables: variables}
  end
end
