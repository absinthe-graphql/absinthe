defmodule Absinthe.Execution.Variable do
  @moduledoc false
  # Represents an meta variable

  defstruct value: nil, type_stack: nil

  alias Absinthe.Type
  alias Absinthe.Language
  alias Absinthe.Execution.Input
  alias Absinthe.Execution.Input.Meta

  # Non null checks here are about whether it's specified as non null via ! in
  # the document itself. It has nothing to do with whether a given argument
  # has been declared non null, that's the job of `Arguments`
  def build(definition, schema_type, outer_type_stack, execution) do
    meta = Meta.build(execution)

    var_name = definition.variable.name
    raw_value = Map.get(execution.variables.raw, var_name)

    {value, meta} = case do_build(definition, raw_value, schema_type, [var_name], meta) do
      {:ok, value, meta} -> {value, meta}
      {:error, meta} -> {:error, meta}
    end

    case Input.process(:variable, meta, execution) do
      {:ok, execution} ->
        {:ok, %__MODULE__{value: value, type_stack: outer_type_stack}, execution}
      {:error, _missing, _invalid, execution} ->
        {:error, execution}
    end
  end

  defp do_build(%{type: %Language.NonNullType{}, variable: var_ast}, nil, schema_type, type_stack, meta) do
    {:error, Meta.put_missing(meta, type_stack, schema_type, var_ast)}
  end

  defp do_build(%{default_value: nil}, nil, _schema_type, _type_stack, meta) do
    {:ok, nil, meta}
  end

  defp do_build(%{default_value: %{value: value}} = definition, nil, schema_type, type_stack, meta) do
    do_build(definition, value, schema_type, type_stack, meta)
  end

  defp do_build(%{type: %Language.NonNullType{type: inner_type}} = definition, value, schema_type, type_stack, meta) do
    do_build(%{definition | type: inner_type}, value, schema_type, type_stack, meta)
  end

  defp do_build(%{type: %Language.ListType{type: inner_type}} = definition, raw_values, schema_type, type_stack, meta) when is_list(raw_values) do
    {values, meta} = list_values(raw_values, %{definition | type: inner_type}, schema_type, ["[]", type_stack], meta)
    {:ok, values, meta}
  end

  defp do_build(%{variable: var_ast}, values, %Type.InputObject{fields: schema_fields}, type_stack, meta) when is_map(values) do
    {values, meta} = map_values(Map.to_list(values), schema_fields, type_stack, var_ast, meta)
    {:ok, values, meta}
  end

  defp do_build(%{variable: var_ast}, value, %Type.Enum{} = enum, type_stack, meta) do
    case Type.Enum.parse(enum, value) do
      {:ok, enum_value} ->
        meta = meta |> add_deprecation_notice(enum_value, enum, [enum_value.value | type_stack], var_ast)
        {:ok, enum_value.value, meta}

      :error ->
        {:error, Meta.put_invalid(meta, type_stack, enum, var_ast)}
    end
  end

  defp do_build(%{variable: var_ast}, value, %Type.Scalar{} = schema_type, type_stack, meta) do
    Input.parse_scalar(value, var_ast, schema_type, type_stack, meta)
  end

  defp do_build(%{variable: var_ast}, _values, schema_type, type_stack, meta) do
    {:error, Meta.put_invalid(meta, type_stack, schema_type, var_ast)}
  end

  defp list_values(items, definition, schema_type, type_stack, meta) do
    do_list_values(items, definition, schema_type, [], type_stack, meta)
  end
  defp do_list_values([], _def, _schema_type, acc, _stack_type, meta) do
    {:lists.reverse(acc), meta}
  end
  defp do_list_values([value | rest], definition, schema_type, acc, type_stack, meta) do
    case do_build(definition, value, schema_type, type_stack, meta) do
      {:ok, nil, meta} ->
        do_list_values(rest, definition, schema_type, acc, type_stack, meta)

      {:ok, item, meta} ->
        do_list_values(rest, definition, schema_type, [item | acc], type_stack, meta)

      {:error, meta} ->
        meta = Meta.put_invalid(meta, type_stack, schema_type, definition.variable)
        do_list_values(rest, definition, schema_type, acc, type_stack, meta)
    end
  end

  # So this sorta sucks.
  # Input objects create their own world where it's simply bare elixir
  # values and schema types, whereas previously it was AST values and schema types
  # There's a fair bit of duplication between what's here, what's earlier in the module,
  # and what exists over in Arguments.ex
  # I don't necessarily think that the duplication is ipso facto bad, but each individual
  # use case should at least live in its own module that gives it some more semantic value

  defp build_map_value(values, %Type.InputObject{fields: schema_fields}, type_stack, var_ast, meta) do
    {values, meta} = map_values(Map.to_list(values), schema_fields, type_stack, var_ast, meta)
    {:ok, values, meta}
  end
  defp build_map_value(raw_values, %Type.List{of_type: inner_type}, type_stack, var_ast, meta) do
    {values, meta} = inner_list_values(raw_values, inner_type, ["[]", type_stack], var_ast, meta)
    {:ok, values, meta}
  end
  defp build_map_value(value, %Type.Field{type: inner_type} = type, type_stack, var_ast, meta) do
    meta = meta |> add_deprecation_notice(type, inner_type, type_stack, var_ast)
    build_map_value(value, inner_type, type_stack, var_ast, meta)
  end
  defp build_map_value(nil, %Type.NonNull{of_type: inner_type}, type_stack, var_ast, meta) do
    {:error, Meta.put_missing(meta, type_stack, inner_type, var_ast)}
  end
  defp build_map_value(value, %Type.NonNull{of_type: inner_type}, type_stack, var_ast, meta) do
    build_map_value(value, inner_type, type_stack, var_ast, meta)
  end
  defp build_map_value(value, %Type.Enum{} = enum, type_stack, var_ast, meta) do
    case Type.Enum.parse(enum, value) do
      {:ok, enum_value} ->
        meta = meta |> add_deprecation_notice(enum_value, enum, [enum_value.value | type_stack], var_ast)
        {:ok, enum_value.value, meta}

      :error ->
        {:error, Meta.put_invalid(meta, type_stack, enum, var_ast)}
    end
  end
  defp build_map_value(value, %Type.Scalar{} = type, type_stack, var_ast, meta) do
    Input.parse_scalar(value, var_ast, type, type_stack, meta)
  end
  defp build_map_value(value, type, type_stack, var_ast, meta) when is_atom(type) do
    real_type = meta.schema.__absinthe_type__(type)
    build_map_value(value, real_type, type_stack, var_ast, meta)
  end

  defp inner_list_values(raw_values, inner_type, type_stack, var_ast, meta) do
    inner_list_values(raw_values, inner_type, type_stack, var_ast, [], meta)
  end

  defp inner_list_values([], _, _, _, acc, meta), do: {:lists.reverse(acc), meta}
  defp inner_list_values([raw_value | rest], inner_type, type_stack, var_ast, acc, meta) do
    case build_map_value(raw_value, inner_type, type_stack, var_ast, meta) do
      {:ok, nil, meta} ->
        inner_list_values(rest, inner_type, type_stack, var_ast, acc, meta)

      {:ok, value, meta} ->
        inner_list_values(rest, inner_type, type_stack, var_ast, [value | acc], meta)

      {:error, meta} ->
        # No need to put an error here because which ever build_map_value clause
        # failed should have added it already.
        inner_list_values(rest, inner_type, type_stack, var_ast, acc, meta)
    end
  end

  defp map_values(items, fields, type_stack, var_ast, meta) do
    # Initialize accumulator
    #
    # We use a list here rather than a map because building a list with `{k, v}`
    # pairs and then using `:maps.from_list` is both faster and produces less
    # garbage.
    do_map_values(items, fields, [], type_stack, var_ast, meta)
  end
  defp do_map_values([], remaining_fields, acc, type_stack, var_ast, meta) do
    Meta.check_missing_fields(remaining_fields, acc, type_stack, var_ast, meta)
  end
  defp do_map_values([{key, raw_value} | rest], schema_fields, acc, type_stack, var_ast, meta) do
    case pop_field(schema_fields, key) do
      {name, schema_field, schema_fields} ->
        case build_map_value(raw_value, schema_field, [key | type_stack], var_ast, meta) do
          {:ok, nil, meta} ->
            do_map_values(rest, schema_fields, acc, type_stack, var_ast, meta)

          {:ok, value, meta} ->
            do_map_values(rest, schema_fields, [{name, value} | acc], type_stack, var_ast, meta)

          {:error, meta} ->
            # No need to put an error here because which ever build_map_value clause
            # failed should have added it already.
            do_map_values(rest, schema_fields, acc, type_stack, var_ast, meta)
        end

      :error ->
        meta = Meta.put_extra(meta, [key | type_stack], var_ast)
        do_map_values(rest, schema_fields, acc, type_stack, var_ast, meta)
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

  defp add_deprecation_notice(meta, %{deprecation: nil}, _, _, _) do
    meta
  end
  defp add_deprecation_notice(meta, %{deprecation: %{reason: reason}}, type, type_stack, ast) do
    details = if reason, do: "; #{reason}", else: ""

    Meta.put_deprecated(meta, type_stack, Type.unwrap(type), ast, fn type_name ->
      &"Variable `#{&1}' (#{type_name}): Deprecated#{details}"
    end)
  end

end
