defmodule Absinthe.Execution.Arguments do
  # Handles the logic around building and validating argument values for a field.

  @moduledoc false

  alias Absinthe.Execution
  alias Absinthe.Type
  alias Absinthe.Language
  alias Absinthe.Execution.Input
  alias Absinthe.Execution.Input.Meta

  # Build an arguments map from the argument definitions in the schema, using the
  # argument values from the query document.
  @doc false
  @spec build(Language.t | Language.t, %{atom => Type.Argument.t}, Execution.t) ::
    {:ok, {%{atom => any}, Execution.t}} | {:error, {[binary], [binary]}, Execution.t}
  def build(ast_field, schema_arguments, execution) do
    meta = Meta.build(execution, variables: execution.variables.processed)

    {values, meta} = add_arguments(ast_field.arguments, schema_arguments, ast_field, meta)

    case Input.process(:argument, meta, execution) do
      {:ok, execution} ->
        {:ok, values, execution}
      {:error, missing, invalid, execution} ->
        {:error, missing, invalid, execution}
    end
  end

  defp add_arguments(arg_asts, schema_arguments, ast_field, meta) do
    map_argument(arg_asts, schema_arguments, [], ast_field, meta)
  end

  defp add_argument(%Language.Variable{name: name} = ast, schema_type, type_stack, meta) do
    retrieve_variable(name, schema_type, type_stack, ast, meta)
  end

  defp add_argument(arg_ast, %Type.NonNull{of_type: inner_type}, type_stack, meta) do
    add_argument(arg_ast, inner_type, type_stack, meta)
  end

  defp add_argument(%Language.Argument{value: value} = ast_node, %Type.Argument{type: inner_type} = type, type_stack, meta) do
    meta = meta |> add_deprecation_notice(type, inner_type, [type.name | type_stack], ast_node)
    add_argument(value, inner_type, [type.name | type_stack], meta)
  end

  defp add_argument(%Language.ListValue{values: values}, %Type.List{of_type: inner_type}, type_stack, meta) do
    real_inner_type = meta.schema.__absinthe_type__(inner_type)
    {acc, meta} = list_argument(values, real_inner_type, ["[]" | type_stack], meta)
    {:ok, acc, meta}
  end

  defp add_argument(%{value: _} = ast, %Type.List{of_type: inner_type}, type_stack, meta) do
    real_inner_type = meta.schema.__absinthe_type__(inner_type)
    {acc, meta} = list_argument([ast], real_inner_type, type_stack, meta)
    {:ok, acc, meta}
  end

  defp add_argument(%Language.ObjectValue{fields: ast_fields} = ast, %Type.InputObject{fields: schema_fields}, type_stack, meta) do
    {acc, meta} = map_argument(ast_fields, schema_fields, type_stack, ast, meta)
    {:ok, acc, meta}
  end

  defp add_argument(%Language.ObjectField{value: value} = ast_node, %Type.Field{type: inner_type} = type, type_stack, meta) do
    meta = meta |> add_deprecation_notice(type, inner_type, [type.name | type_stack], ast_node)
    add_argument(value, inner_type, [type.name | type_stack], meta)
  end

  defp add_argument(%{value: value} = ast, %Type.Enum{} = enum, type_stack, meta) do
    case Type.Enum.parse(enum, value) do
      {:ok, enum_value} ->
        meta = meta |> add_deprecation_notice(enum_value, enum, [enum_value.value | type_stack], ast)
        {:ok, enum_value.value, meta}

      :error ->
        {:error, Meta.put_invalid(meta, type_stack, enum, ast)}
    end
  end

  defp add_argument(%{value: value} = ast, %Type.Scalar{} = type, type_stack, meta) do
    Input.parse_scalar(value, ast, type, type_stack, meta)
  end

  defp add_argument(_ast, nil, type_stack, meta) do
    raise ArgumentError, internal_schema_error(meta.schema, type_stack)
  end

  defp add_argument(ast, type, type_stack, meta) when is_atom(type) do
    real_type = meta.schema.__absinthe_type__(type)
    add_argument(ast, real_type, type_stack, meta)
  end

  defp add_argument(ast, type, type_stack, meta) do
    {:error, Meta.put_invalid(meta, type_stack, type, ast)}
  end

  defp add_deprecation_notice(meta, %{deprecation: nil}, _, _, _) do
    meta
  end
  defp add_deprecation_notice(meta, %{deprecation: %{reason: reason}}, type, type_stack, ast) do
    details = if reason, do: "; #{reason}", else: ""

    Meta.put_deprecated(meta, type_stack, Type.unwrap(type), ast, fn type_name ->
      &"Argument `#{&1}' (#{type_name}): Deprecated#{details}"
    end)
  end

  defp retrieve_variable(name, schema_type, type_stack, ast, meta) do
    full_type_stack = fillout_stack(schema_type, [], meta.schema)
    meta.variables
    |> Map.get(name)
    |> case do
      # The variable exists, and it has the same
      # type as the argument in the schema.
      # yay! we can use it as is.
      %{value: value, type_stack: ^full_type_stack} ->
        do_retrieve_variable(value, schema_type, type_stack, ast, meta)
      _ ->
        do_retrieve_variable(nil, schema_type, type_stack, ast, meta)
    end
  end

  defp do_retrieve_variable(nil, %Type.NonNull{of_type: inner_type}, type_stack, ast, meta) do
    {:error, Meta.put_missing(meta, type_stack, inner_type, ast)}
  end
  defp do_retrieve_variable(nil, _, _, _, meta) do
    # Don't put a missing error, but also don't put any value for the variable
    {:error, meta}
  end
  defp do_retrieve_variable(value, _, _, _, meta) do
    {:ok, value, meta}
  end

  # For a given schema node, build the stack of types it contains.
  # This is necessary because when comparing the type of a processed variable
  # with the type of the desired argument we must compare not only the inner
  # most type, but also how many layers of lists it's inside of.
  #
  # Otherwise a variable of type String could substitute for an argument that
  # wanted [String]
  #
  # NonNull type's don't get added to the stack because whether a variable was
  # specified as non null in the document has no bearing on whether or not
  # it can be substituted for a non null marked argument.
  #
  # See Variables.validate_definition_type/2 for the corresponding logic
  # used when building a variable.
  defp fillout_stack(%Type.NonNull{of_type: inner_type}, acc, schema) do
    fillout_stack(inner_type, acc, schema)
  end
  defp fillout_stack(%Type.List{of_type: inner_type}, acc, schema) do
    fillout_stack(inner_type, [Type.List | acc], schema)
  end
  defp fillout_stack(%{name: name}, acc, _schema) do
    [name | acc]
  end
  defp fillout_stack(nil, acc, schema) do
    raise ArgumentError, internal_schema_error(schema, acc)
  end
  defp fillout_stack(identifier, acc, schema) do
    identifier
    |> schema.__absinthe_type__
    |> fillout_stack(acc, schema)
  end

  # Go through a list arguments belonging to a list type.
  # For each item try to resolve it with add_argument.
  # If it's a valid item, accumulate, if not, don't.
  defp list_argument(values, inner_type, type_stack, meta) do
    do_list_argument(values, inner_type, [], type_stack, meta)
  end
  defp do_list_argument([], _, acc, _, meta), do: {:lists.reverse(acc), meta}
  defp do_list_argument([value | rest], inner_type, acc, type_stack, meta) do
    case add_argument(value, inner_type, type_stack, meta) do
      {:ok, item, meta} ->
        do_list_argument(rest, inner_type, [item | acc], type_stack, meta)
      {:error, meta} ->
        do_list_argument(rest, inner_type, acc, type_stack, meta)
    end
  end

  # Go through a list of arguments belonging to an object type
  # For each item, find the corresponding field within the object
  # If a field exists, and if the
  # If it's a valid item, accumulate,
  defp map_argument(items, fields, type_stack, root_node, meta) do
    do_map_argument(items, fields, [], type_stack, root_node, meta)
  end

  defp do_map_argument([], remaining_fields, acc, type_stack, root_node, meta) do
    Meta.check_missing_fields(remaining_fields, acc, type_stack, root_node, meta)
  end
  defp do_map_argument([value | rest], schema_fields, acc, type_stack, root_node, meta) do
    case pop_field(schema_fields, value) do
      {name, schema_field, schema_fields} ->
        # The value refers to a legitimate field in the schema,
        # now see if it can be handled properly.
        case add_argument(value, schema_field, type_stack, meta) do
          {:ok, item, meta} ->
            do_map_argument(rest, schema_fields, [{name, item} | acc], type_stack, root_node, meta)
          {:error, meta} ->
            do_map_argument(rest, schema_fields, acc, type_stack, root_node, meta)
        end

      :error ->
        meta = Meta.put_extra(meta, [value.name | type_stack], root_node)
        do_map_argument(rest, schema_fields, acc, type_stack, root_node, meta)
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

  defp internal_schema_error(schema, stack) do
    """
    Schema #{schema} is internally inconsistent!

    Type referenced at #{inspect stack} does not exist in the schema, even
    though items in the schema refer to it. This is bad!

    This clause should become irrelevant when schemas check internal consistency
    at compile time.
    """
  end
end
