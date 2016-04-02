defmodule Absinthe.Execution.Input.Meta do
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
    item = %{ast: ast, name: type_stack, type: type, msg: Map.get(opts, :msg)}

    Map.update!(meta, key, &[item | &1])
  end

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
end
