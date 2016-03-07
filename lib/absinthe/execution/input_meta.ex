defmodule Absinthe.Execution.InputMeta do
  @moduledoc false

  # Includes common functionality for handling Variables and Arguments

  alias Absinthe.Execution
  alias Absinthe.Type

  defstruct schema: nil,
    missing: [],
    invalid: [],
    deprecated: [],
    extra: [],
    variables: %{}

  def build(%Execution{schema: schema}, attrs \\ []) do
    %__MODULE__{schema: schema}
    |> struct(attrs)
  end

  def put_invalid(meta, type_stack, type, ast) do
    put_meta(meta, :invalid, type_stack, Type.unwrap(type), ast)
  end

  def put_missing(meta, type_stack, type, ast) do
    put_meta(meta, :missing, type_stack, Type.unwrap(type), ast)
  end
  def put_extra(meta, type_stack, ast) do
    put_meta(meta, :extra, type_stack, nil, ast)
  end
  def put_deprecated(meta, type_stack, type, ast, msg \\ "") do
    put_meta(meta, :deprecated, type_stack, type, ast, %{msg: msg})
  end

  defp put_meta(meta, key, type_stack, type, ast, opts \\ %{})
  defp put_meta(meta, key, type_stack, type, ast, opts) when is_atom(type) and type != nil do
    real_type = type |> meta.schema.__absinthe_type__

    put_meta(meta, key, type_stack, real_type, ast, opts)
  end
  defp put_meta(meta, key, type_stack, type, ast, opts) when is_list(type_stack) do
    name = type_stack |> dotted_name

    item = %{ast: ast, name: name, type: type, msg: Map.get(opts, :msg)}

    Map.update!(meta, key, &[item | &1])
  end

  def process_errors(execution, meta, kind, key, default_msg) do
    meta
    |> Map.fetch!(key)
    |> Enum.reduce({execution, []}, fn
      %{name: name, ast: ast, type: type, msg: msg}, {exec, names} ->
        exec = exec |> Execution.put_error(kind, name, error_message(msg || default_msg, type), at: ast)

        {exec, [name | names]}
    end)
  end

  defp error_message(msg, nil), do: msg
  defp error_message(msg, type) when is_function(msg) do
    msg.(type.name)
  end
  defp error_message(msg, _), do: msg

  # Having gone through the list of given values, go through
  # the remaining fields and populate any defaults.
  # TODO see if we need to add an error around non null fields
  def check_missing_fields(remaining_fields, acc, type_stack, var_ast, meta) do
    acc = :maps.from_list(acc)

    {acc, meta} = Enum.reduce(remaining_fields, {acc, meta}, fn
      {name, %{type: %Type.NonNull{of_type: inner_type}, deprecation: nil}}, {acc, meta} ->
        {acc, put_missing(meta, [name | type_stack], inner_type, var_ast)}

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

  @spec dotted_name([binary]) :: binary
  def dotted_name(names) do
    names
    |> do_dotted_names([])
    |> IO.iodata_to_binary
  end

  defp do_dotted_names([name | []], acc) do
    [to_string(name) | acc]
  end
  defp do_dotted_names(["[]" | rest], acc) do
    do_dotted_names(rest, ["[]" | acc])
  end
  defp do_dotted_names([name | rest], acc) do
    do_dotted_names(rest, [ ".", to_string(name) | acc])
  end
end
