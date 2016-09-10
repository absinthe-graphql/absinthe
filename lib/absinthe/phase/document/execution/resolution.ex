defmodule Absinthe.Phase.Document.Execution.Resolution do
  @moduledoc """
  Runs resolution functions in a new blueprint.

  While this phase starts with a blueprint, it returns an annotated value tree.
  """

  alias Absinthe.Blueprint.Document
  alias Absinthe.Phase.Document.Execution
  alias Absinthe.{Blueprint, Type, Schema}

  use Absinthe.Phase

  def run(bp_root, context, root_value) do
    bp_root = Blueprint.update_current(bp_root, fn
      op ->
        field = %Absinthe.Execution.Field{
          context: context,
          root_value: root_value,
          schema: bp_root.schema
        }
        resolution = resolve_operation(op, bp_root, field, root_value)
        %{op | resolution: resolution}
    end)
    {:ok, bp_root}
  end

  def resolve_operation(operation, bp_root, info, source) do
    %Blueprint.Document.Result.Object{
      name: operation.name,
      fields: resolve_fields(operation, bp_root, info, source),
    }
  end

  def resolve_field(field, bp_root, info, source) do
    resolution_function = field.schema_node.resolve || fn _, _ ->
      {:ok, Map.get(source, field.schema_node.__reference__.identifier)}
    end

    field.arguments
    |> Absinthe.Blueprint.Input.Argument.value_map
    |> resolution_function.(%{info | source: source})
    |> build_result(bp_root, field, info, source)
  end

  defp build_result({:ok, result}, bp_root, field, info, source) do
    full_type = Type.expand(field.schema_node.type, info.schema)
    walk_result(result, bp_root, field, full_type, info)
  end
  defp build_result({:error, msg}, bp_root, _, _, _) do
    {:error, %{message: msg}}
  end
  defp build_result(other, _, field, info, source) do
    raise """
    Resolution function did not return `{:ok, val}` or `{:error, reason}`
    Resolving field: #{field.name}
    Resolving on: #{inspect source}
    Got: #{inspect other}
    """
  end

  @doc """
  Handle the result of a resolution function
  """
  ## Limitations
  # - No non null checking
  # -

  ## Leaf bp_nodes

  def walk_result(nil, _, bp_node, _, _) do
    {:ok, %Blueprint.Document.Result.Leaf{
      name: bp_node.alias || bp_node.name,
      value: nil
    }}
  end
  # Resolve value of type scalar
  def walk_result(value, _, bp_node, %Type.Scalar{} = schema_type, _) do
    {:ok, %Blueprint.Document.Result.Leaf{
      name: bp_node.alias || bp_node.name,
      value: Type.Scalar.serialize(schema_type, value)
    }}
  end
  # Resolve Enum type
  def walk_result(value, bp_root, bp_node, %Type.Enum{} = schema_type, info) do
    {:ok, %Blueprint.Document.Result.Leaf{
      name: bp_node.alias || bp_node.name,
      value: Type.Enum.serialize!(schema_type, value)
    }}
  end

  def walk_result(value, bp_root, bp_node, %Type.Object{} = type, info) do
    {:ok, %Blueprint.Document.Result.Object{
      name: bp_node.alias || bp_node.name,
      fields: resolve_fields(bp_node, bp_root, info, value),
    }}
  end

  def walk_result(values, bp_root, bp_node, %Type.List{of_type: inner_type}, info) do
    values =
      values
      |> List.wrap
      |> walk_results(bp_root, bp_node, inner_type, info)

    {:ok, %Blueprint.Document.Result.List{name: bp_node.name, values: values}}
  end

  def walk_result(nil, _, _, %Type.NonNull{}, _) do
    # We may want to raise here because this is a programmer error in some sense
    # not a graphql user error.
    # TODO: handle default value. Are there even default values on output types?
    {:error, "Supposed to be non nil"}
  end

  def walk_result(val, bp_root, bp_node, %Type.NonNull{of_type: inner_type}, info) do
    walk_result(val, bp_root, bp_node, inner_type, info)
  end
  def walk_result(_, _, _, _, _) do
    raise "Could not walk result"
  end

  defp walk_results(values, bp_root, bp_node, inner_type, info, acc \\ [])
  defp walk_results([], bp_root, _, _, _, acc), do: :lists.reverse(acc)
  defp walk_results([value | values], bp_root, bp_node, inner_type, info, acc) do
    result = walk_result(value, bp_root, bp_node, inner_type, info)
    walk_results(values, bp_root, bp_node, inner_type, info, [result | acc])
  end

  defp resolve_fields(parent, bp_root, info, source) do
    parent.fields
    |> Enum.filter(&field_applies?(&1, bp_root, source, parent.schema_node))
    |> do_resolve_fields(bp_root, info, source, [])
  end

  defp do_resolve_fields(fields, bp_root, info, source, acc)
  defp do_resolve_fields([], _, _, _, acc), do: :lists.reverse(acc)
  defp do_resolve_fields([%{schema_node: nil} | fields], bp_root, info, source, acc) do
    do_resolve_fields(fields, bp_root, info, source, acc)
  end
  defp do_resolve_fields([field | fields], bp_root, info, source, acc) do
    result = resolve_field(field, bp_root, info, source)
    do_resolve_fields(fields, bp_root, info, source, [result | acc])
  end

  def field_applies?(%{type_conditions: []}, _, _, _) do
    true
  end
  def field_applies?(field, bp_root, source, schema_type) do
    target_type = find_target_type(schema_type, bp_root.schema)
    field.type_conditions
    |> Enum.map(&(bp_root.schema.__absinthe_type__(&1.name)))
    |> Enum.all?(&passes_type_condition?(&1, target_type))
  end

  def find_target_type(schema_type, schema) when is_atom(schema_type) do
    schema.__absinthe_type__(schema_type)
  end
  def find_target_type(%{type: type}, schema) do
    find_target_type(type, schema)
  end

  # TODO: Interface, etc
  def passes_type_condition?(equal, equal), do: true
  def passes_type_condition?(_, _), do: false

end
