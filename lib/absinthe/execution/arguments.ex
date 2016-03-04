defmodule Absinthe.Execution.Arguments do
  # Handles the logic around building and validating argument values for a field.

  @moduledoc false

  alias Absinthe.Execution
  alias Absinthe.Type
  alias Absinthe.Language

  # Build an arguments map from the argument definitions in the schema, using the
  # argument values from the query document.
  @doc false
  @spec build(Language.t | Language.t, %{atom => Type.Argument.t}, Execution.t) ::
    {:ok, {%{atom => any}, Execution.t}} | {:error, {[binary], [binary]}, Execution.t}
  def build(ast_field, schema_arguments, execution) do
    {values, post_execution} = add_arguments(ast_field.arguments, schema_arguments, execution)
    {:ok, values, post_execution}
  end

  defp add_arguments(arg_asts, schema_arguments, execution) do
    acc_map_argument(arg_asts, schema_arguments, %{}, execution)
  end

  defp add_argument(arg_ast, %Type.NonNull{of_type: inner_type}, execution) do
    real_inner_type = execution.schema.__absinthe_type__(inner_type)
    add_argument(arg_ast, real_inner_type, execution)
  end

  defp add_argument(%Language.Argument{value: value}, %Type.Argument{type: inner_type}, execution) do
    real_inner_type = case inner_type do
      inner_type when is_atom(inner_type) ->
        execution.schema.__absinthe_type__(inner_type)
      inner_type -> inner_type
    end

    add_argument(value, real_inner_type, execution)
  end

  defp add_argument(%Language.ListValue{values: values}, %Type.List{of_type: inner_type}, execution) do
    real_inner_type = execution.schema.__absinthe_type__(inner_type)
    {acc, exec} = acc_list_argument(values, real_inner_type, [], execution)
    {:ok, acc, exec}
  end

  defp add_argument(%Language.ObjectValue{fields: ast_fields}, %Type.InputObject{fields: schema_fields}, execution) do
    {acc, execution} = acc_map_argument(ast_fields, schema_fields, %{}, execution)
    {:ok, acc, execution}
  end

  defp add_argument(%Language.ObjectField{value: value}, %Type.Field{type: inner_type}, execution) do
    real_inner_type = execution.schema.__absinthe_type__(inner_type)
    add_argument(value, real_inner_type, execution)
  end

  defp add_argument(%{value: value}, %Type.Scalar{parse: parser}, execution) do
    case parser.(value) do
      {:ok, coerced_value} ->
        {:ok, coerced_value, execution}
      :error ->
        {:error, execution}
    end
  end

  defp add_argument(ast, schema, execution) do
    IO.puts "~~~~~~~~~~~UNKNOWN~~~~~~~~~~~"
    ast |> debug
    schema |> debug
    {:error, execution}
  end

  # Go through a list arguments belonging to a list type.
  # For each item try to resolve it with add_argument.
  # If it's a valid item, accumulate, if not, don't.
  defp acc_list_argument([], _, acc, execution), do: {:lists.reverse(acc), execution}
  defp acc_list_argument([value | rest], inner_type, acc, execution) do
    case add_argument(value, inner_type, execution) do
      {:ok, item, execution} ->
        acc_list_argument(rest, inner_type, [item | acc], execution)
      {:error, execution} ->
        acc_list_argument(rest, inner_type, acc, execution)
    end
  end

  # Go through a list of arguments belonging to an object type
  # For each item, find the corresponding field within the object
  # If a field exists, and if the
  # If it's a valid item, accumulate,
  defp acc_map_argument([], remaining_fields, acc, execution) do
    acc = Enum.reduce(remaining_fields, acc, fn
      # No default, carry on
      {_, %{default_value: nil}}, acc ->
        acc

      {name, %{default_value: default}}, acc ->
        case Map.get(acc, name) do
          nil -> Map.put(acc, name, default)
          _ -> acc
        end
    end)
    {acc, execution}
  end
  defp acc_map_argument([value | rest], schema_fields, acc, execution) do
    case pop_field(schema_fields, value) do
      {name, schema_field, schema_fields} ->
        # The value refers to a legitimate field in the schema,
        # now see if it can be handled properly.
        case add_argument(value, schema_field, execution) do
          {:ok, item, execution} ->
            acc_map_argument(rest, schema_fields, Map.put(acc, name, item), execution)
          {:error, execution} ->
            acc_map_argument(rest, schema_fields, acc, execution)
        end

      :error ->
        # Todo: register field as unnecssary
        acc_map_argument(rest, schema_fields, acc, execution)
    end
  end


  # Given a document argument, pop the relevant schema argument
  # The reason for popping the arg is that it's an easy way to prevent using
  # the same argument name twice.
  defp pop_field(schema_arguments, %{name: name}) do
    name = String.to_existing_atom(name)

    case Map.pop(schema_arguments, name) do
      {nil, _} -> :error
      {val, args} -> {name, val, args}
    end
  rescue
    ArgumentError -> :error
  end

  defp debug(val) do
    IO.puts "--------------------------------------------"
    IO.inspect val
  end
end
