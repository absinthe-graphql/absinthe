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
    meta = %{
      schema: execution.schema,
      missing: [],
      invalid: [],
      extra: [],
      type_stack: [],
      variables: execution.variables.processed
    }

    {values, post_meta} = add_arguments(ast_field.arguments, schema_arguments, meta)

    {execution, missing} = process_errors(execution, post_meta, :missing, fn type_name -> &"Argument `#{&1}' (#{type_name}): Not provided" end)
    {execution, invalid} = process_errors(execution, post_meta, :invalid, fn type_name -> &"Argument `#{&1}' (#{type_name}): Invalid value provided" end)

    case Enum.any?(missing) || Enum.any?(invalid) do
      false ->
        {:ok, values, execution}
      true ->
        {:error, missing, invalid, execution}
    end
  end

  defp process_errors(execution, meta, key, msg) do
    meta
    |> Map.fetch!(key)
    |> Enum.reduce({execution, []}, fn
      %{type_stack: type_stack, ast: ast, type: type}, {exec, names} ->
        name_to_report = type_stack |> dotted_name
        exec = exec |> Execution.put_error(:argument, name_to_report, msg.(type.name), at: ast)
        {exec, [name_to_report | names]}
    end)
  end

  @spec dotted_name([binary]) :: binary
  defp dotted_name(names) do
    names |> Enum.reverse |> Enum.join(".")
  end

  defp add_arguments(arg_asts, schema_arguments, meta) do
    acc_map_argument(arg_asts, schema_arguments, %{}, [], meta)
  end

  defp add_argument(%Language.Variable{name: name}, schema_type, type_stack, meta) do
    retrieve_variable(name, schema_type, type_stack, meta)
  end

  defp add_argument(arg_ast, %Type.NonNull{of_type: inner_type}, type_stack, meta) do
    add_argument(arg_ast, inner_type, type_stack, meta)
  end

  defp add_argument(%Language.Argument{value: value}, %Type.Argument{type: inner_type} = type, type_stack, meta) do
    add_argument(value, inner_type, [type.name | type_stack], meta)
  end

  defp add_argument(%Language.ListValue{values: values}, %Type.List{of_type: inner_type}, type_stack, meta) do
    real_inner_type = meta.schema.__absinthe_type__(inner_type)
    {acc, meta} = acc_list_argument(values, real_inner_type, [], type_stack, meta)
    {:ok, acc, meta}
  end

  defp add_argument(%Language.ObjectValue{fields: ast_fields}, %Type.InputObject{fields: schema_fields}, type_stack, meta) do
    {acc, meta} = acc_map_argument(ast_fields, schema_fields, %{}, type_stack, meta)
    {:ok, acc, meta}
  end

  defp add_argument(%Language.ObjectField{value: value}, %Type.Field{type: inner_type} = type, type_stack, meta) do
    add_argument(value, inner_type, [type.name | type_stack], meta)
  end

  defp add_argument(%{value: value} = ast, %Type.Enum{} = enum, type_stack, meta) do
    case Type.Enum.parse(enum, value) do
      {:ok, value} ->
        {:ok, value, meta}

      :error ->
        {:error, put_meta(meta, :invalid, type_stack, enum, ast)}
    end
  end

  defp add_argument(%{value: value} = ast, %Type.Scalar{parse: parser} = type, type_stack, meta) do
    case parser.(value) do
      {:ok, coerced_value} ->
        {:ok, coerced_value, meta}

      :error ->
        {:error, put_meta(meta, :invalid, type_stack, type, ast)}
    end
  end

  defp add_argument(ast, nil, type_stack, meta) do
    raise ArgumentError, """
    Schema #{meta.schema} is internally inconsistent!

    Type referenced at #{inspect type_stack} does not exist

    This clause should become irrelevant when schemas check internal consistency
    at compile time.
    """
  end

  defp add_argument(ast, type, type_stack, meta) when is_atom(type) do
    real_type = meta.schema.__absinthe_type__(type)
    add_argument(ast, real_type, type_stack, meta)
  end

  defp add_argument(ast, type, type_stack, meta) do
    {:error, put_meta(meta, :invalid, type_stack, type, ast)}
  end

  defp put_meta(meta, key, type_stack, type, ast) when is_atom(type) do
    real_type = meta.schema.__absinthe_type__(type)
    put_meta(meta, key, type_stack, real_type, ast)
  end
  defp put_meta(meta, key, type_stack, type, ast) when is_list(type_stack) and is_map(type) do
    Map.update!(meta, key, &[%{ast: ast, type_stack: type_stack, type: type} | &1])
  end

  defp retrieve_variable(name, schema_type, _type_stack, meta) do
    full_type_stack = fillout_stack(schema_type, [], meta.schema)
    meta.variables
    |> Map.get(name)
    |> case do
      # The variable exists, and it has the same
      # type as the argument in the schema.
      # yay! we can use it as is.
      %{value: value, type_stack: ^full_type_stack} ->
        {:ok, value, meta}
      _ ->
        {:error, meta}
    end
  end

  # For a given schema node, build the stack of types it contains.
  # This is necessary because when comparing the type of a processed variable
  # with the type of the desired argument we must compare not simply the inner
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
  defp fillout_stack(identifier, acc, schema) do
    identifier
    |> schema.__absinthe_type__
    |> fillout_stack(acc, schema)
  end

  # Go through a list arguments belonging to a list type.
  # For each item try to resolve it with add_argument.
  # If it's a valid item, accumulate, if not, don't.
  defp acc_list_argument([], _, acc, _, meta), do: {:lists.reverse(acc), meta}
  defp acc_list_argument([value | rest], inner_type, acc, type_stack, meta) do
    case add_argument(value, inner_type, type_stack, meta) do
      {:ok, item, meta} ->
        acc_list_argument(rest, inner_type, [item | acc], type_stack, meta)
      {:error, meta} ->
        acc_list_argument(rest, inner_type, acc, type_stack, meta)
    end
  end

  # Go through a list of arguments belonging to an object type
  # For each item, find the corresponding field within the object
  # If a field exists, and if the
  # If it's a valid item, accumulate,
  defp acc_map_argument([], remaining_fields, acc, type_stack, meta) do
    # Having gone through the list of given values, go through
    # the remaining fields and populate any defaults.
    # TODO see if we need to add an error around non null fields
    {acc, meta} = Enum.reduce(remaining_fields, {acc, meta}, fn
      {name, %{type: %Type.NonNull{of_type: inner_type}, deprecation: nil}}, {acc, meta} ->
        {acc, put_meta(meta, :missing, [name | type_stack], inner_type, nil)}

      {_, %{default_value: nil}}, {acc, meta} ->
        {acc, meta}

      {name, %{default_value: default}}, {acc, meta} ->
        case Map.get(acc, name) do
          nil -> {Map.put(acc, name, default), meta}
          _ -> {acc, meta}
        end
    end)
    {acc, meta}
  end
  defp acc_map_argument([value | rest], schema_fields, acc, type_stack, meta) do
    case pop_field(schema_fields, value) do
      {name, schema_field, schema_fields} ->
        # The value refers to a legitimate field in the schema,
        # now see if it can be handled properly.
        case add_argument(value, schema_field, type_stack, meta) do
          {:ok, item, meta} ->
            acc_map_argument(rest, schema_fields, Map.put(acc, name, item), type_stack, meta)
          {:error, meta} ->
            acc_map_argument(rest, schema_fields, acc, type_stack, meta)
        end

      :error ->
        # Todo: register field as unnecssary
        acc_map_argument(rest, schema_fields, acc, type_stack, meta)
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
end
