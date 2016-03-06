defmodule Absinthe.Execution.Variable do
  @moduledoc false
  # Represents an execution variable

  defstruct value: nil, type_stack: nil

  alias Absinthe.Type
  alias Absinthe.Language
  alias Absinthe.Execution

  # Non null checks here are about whether it's specified as non null via ! in
  # the document itself. It has nothing to do with whether a given argument
  # has been declared non null, that's the job of `Arguments`
  def build(definition, schema_type, outer_type_stack, execution) do
    raw_value = Map.get(execution.variables.raw, definition.variable.name)

    case do_build(definition, raw_value, schema_type, execution) do
      {:ok, value, execution} ->
        {:ok, %__MODULE__{value: value, type_stack: outer_type_stack}, execution}

      other ->
        other
    end
  end
  defp do_build(%{type: %Language.NonNullType{type: inner_type}, variable: variable}, nil, _, execution) do
    execution = Execution.put_error(execution, :variable, variable.name,
      &"Variable `#{&1}' (#{inner_type.name}): Not provided",
      at: inner_type)
    {:error, execution}
  end

  defp do_build(%{default_value: nil}, nil, _schema_type, execution) do
    {:ok, nil, execution}
  end

  defp do_build(%{default_value: %{value: value}} = definition, nil, schema_type, execution) do
    do_build(definition, value, schema_type, execution)
  end

  defp do_build(%{type: %Language.NonNullType{type: inner_type}} = definition, value, schema_type, execution) do
    do_build(%{definition | type: inner_type}, value, schema_type, execution)
  end

  defp do_build(%{type: %Language.ListType{type: inner_type}} = definition, raw_values, schema_type, execution) when is_list(raw_values) do
    {values, execution} = acc_list_values(raw_values, %{definition | type: inner_type}, schema_type, [], execution)
    {:ok, values, execution}
  end

  defp do_build(%{variable: _}, values, %Type.InputObject{fields: schema_fields}, execution) when is_map(values) do
    {values, execution} = acc_map_values(Map.to_list(values), schema_fields, %{}, execution)
    {:ok, values, execution}
  end

  defp do_build(%{variable: var_ast}, value, %Type.Enum{} = enum, execution) do
    case Type.Enum.parse(enum, value) do
      {:ok, value} ->
        {:ok, value, execution}

      :error ->
        execution = Execution.put_error(execution, :variable, var_ast.name, &"Argument `#{&1}' (#{enum.name}): Invalid value provided", at: var_ast)
        {:error, execution}
    end
  end

  defp do_build(%{variable: var_ast}, value, %Type.Scalar{} = schema_type, execution) do
    case schema_type.parse.(value) do
      {:ok, coerced_value} ->
        {:ok, coerced_value, execution}
      :error ->
        # TODO: real error message
        execution = Execution.put_error(execution, :variable, var_ast.name, &"Argument `#{&1}' (#{schema_type.name}): Invalid value provided", at: var_ast)
        {:error, execution}
    end
  end

  defp do_build(%{variable: var_ast}, _values, schema_type, execution) do
    execution = Execution.put_error(execution, :variable, var_ast.name, &"Argument `#{&1}' (#{schema_type.name}): Invalid value provided", at: var_ast)
    {:error, execution}
  end

  defp acc_list_values([], _, _, acc, execution), do: {:lists.reverse(acc), execution}
  defp acc_list_values([value | rest], definition, schema_type, acc, execution) do
    case do_build(definition, value, schema_type, execution) do
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
      {name, %{type: %Type.NonNull{}, deprecation: nil}}, {acc, exec} ->
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

end
