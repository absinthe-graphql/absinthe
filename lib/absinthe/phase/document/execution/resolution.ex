defmodule Absinthe.Phase.Document.Execution.Resolution do
  @moduledoc """
  Runs resolution functions in a new blueprint.

  While this phase starts with a blueprint, it returns an annotated value tree.
  """

  alias Absinthe.{Blueprint, Type, Phase}

  alias __MODULE__

  alias Absinthe.Phase
  use Absinthe.Phase

  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(bp_root, options \\ []) do
    context = Keyword.get(options, :context, %{})
    root_value = Keyword.get(options, :root_value, %{})
    result = case Blueprint.current_operation(bp_root) do
      nil ->
        bp_root
      op ->
        field = %Resolution.Info{
          adapter: bp_root.adapter,
          context: context,
          root_value: root_value,
          schema: bp_root.schema,
          source: root_value,
        }
        resolution = resolve_operation(op, bp_root, field, root_value)
        put_in(bp_root.result.resolution, resolution)
    end
    {:ok, result}
  end

  def resolve_operation(operation, bp_root, info, source) do
    info = %{
      info |
      parent_type: bp_root.schema.__absinthe_type__(operation.type)
    }
    %Blueprint.Document.Result.Object{
      emitter: operation,
      fields: resolve_fields(operation, bp_root, info, source),
    }
  end

  def resolve_field(field, bp_root, info, source) do
    info = update_info(info, field, source)

    field.arguments
    |> Absinthe.Blueprint.Input.Argument.value_map
    |> call_resolution_function(field, info, source)
    |> build_result(bp_root, field, info, source)
  end

  defp resolve_fields(parent, bp_root, info, source) do
    parent_type = case parent.schema_node do
      %Type.Field{} = schema_node ->
        info.schema.__absinthe_type__(schema_node.type)
      other ->
        other
    end
    info = %{info | parent_type: parent_type}

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

  defp build_result({:ok, result}, bp_root, field, info, _) do
    full_type = Type.expand(field.schema_node.type, info.schema)
    walk_result(result, bp_root, field, full_type, info)
  end
  defp build_result({:error, msg}, _, field, info, _) do
    message = ~s(In field "#{field.name}": #{msg})
    full_type = Type.expand(field.schema_node.type, info.schema)
    to_result(full_type, emitter: field)
    |> put_error(error(field, message))
  end
  defp build_result(other, _, field, _, source) do
    raise Absinthe.ExecutionError, """
    Resolution function did not return `{:ok, val}` or `{:error, reason}`
    Resolving field: #{field.name}
    Resolving on: #{inspect source}
    Got: #{inspect other}
    """
  end

  # Introspection Field
  defp call_resolution_function(args, %{schema_node: %{name: "__" <> _}} = field, info, _) do
    field.schema_node.resolve.(args, info)
  end
  # Interface Field
  defp call_resolution_function(args, %{schema_node: schema_node} = field, %{parent_type: %Type.Interface{}} = info, source) when not is_nil(schema_node) do
    concrete_type = Type.Interface.resolve_type(info.parent_type, source, info)
    concrete_schema_node = Map.fetch!(concrete_type.fields, field.schema_node.__reference__.identifier)
    # Try again, using the concrete type/field schema node
    call_resolution_function(
      args,
      put_in(field.schema_node, concrete_schema_node),
      put_in(info.parent_type, concrete_type),
      source
    )
  end
  # Field without a resolver
  defp call_resolution_function(args, %{schema_node: %{resolve: nil}} = field, info, source) do
    case info.schema.__absinthe_custom_default_resolve__ do
      nil ->
        {:ok, Map.get(source, field.schema_node.__reference__.identifier)}
      fun ->
        fun.(args, info)
    end
  end
  # Everything else
  defp call_resolution_function(args, field, info, _source) do
    Type.Field.resolve(field.schema_node, args, info)
  end

  defp update_info(info, field, source) do
    %{
      info |
      source: source,
      # This is so that the function can know what field it's in.
      definition: field.schema_node
    }
  end

  @doc """
  Handle the result of a resolution function
  """
  ## Limitations
  # - No non null checking
  # -

  ## Leaf bp_nodes

  def walk_result(nil, _, bp_node, _, _) do
    to_result(
      nil,
      emitter: bp_node,
      value: nil,
    )
  end
  # Resolve value of type scalar
  def walk_result(value, _, bp_node, %Type.Scalar{} = schema_type, _) do
    to_result(
      schema_type,
      emitter: bp_node,
      value: Type.Scalar.serialize(schema_type, value),
    )
  end
  # Resolve Enum type
  def walk_result(value, _, bp_node, %Type.Enum{} = schema_type, _) do
    to_result(
      schema_type,
      emitter: bp_node,
      value: Type.Enum.serialize!(schema_type, value),
    )
  end

  def walk_result(value, bp_root, bp_node, %Type.Object{} = schema_type, info) do
    to_result(
      schema_type,
      emitter: bp_node,
      fields: resolve_fields(bp_node, bp_root, info, value),
    )
  end

  def walk_result(value, bp_root, bp_node, %Type.Interface{} = schema_type, info) do
    to_result(
      schema_type,
      emitter: bp_node,
      fields: resolve_fields(bp_node, bp_root, info, value),
    )
  end

  def walk_result(value, bp_root, bp_node, %Type.Union{} = schema_type, info) do
    to_result(
      schema_type,
      emitter: bp_node,
      fields: resolve_fields(bp_node, bp_root, info, value)
    )
  end

  def walk_result(values, bp_root, bp_node, %Type.List{of_type: inner_type} = schema_type, info) do
    values =
      values
      |> List.wrap
      |> walk_results(bp_root, bp_node, inner_type, info)

    to_result(
      schema_type,
      emitter: bp_node,
      values: values,
    )
  end

  def walk_result(nil, _, bp_node, %Type.NonNull{} = schema_type, info) do
    to_result(schema_type, emitter: bp_node)
    |> put_error(error(node, "Cannot return null for non-nullable field #{info.parent_type.name}.#{bp_node.name}"))
  end

  def walk_result(val, bp_root, bp_node, %Type.NonNull{of_type: inner_type}, info) do
    walk_result(val, bp_root, bp_node, inner_type, info)
  end
  def walk_result(_value, _bp_root, _bp_node, _schema_node, _info) do
    raise "Could not walk result."
  end

  @result_modules %{
    Type.Scalar => Blueprint.Document.Result.Leaf,
    Type.Enum => Blueprint.Document.Result.Leaf,
    Type.Object => Blueprint.Document.Result.Object,
    Type.Interface => Blueprint.Document.Result.Object,
    Type.Union => Blueprint.Document.Result.Object,
    Type.List => Blueprint.Document.Result.List,
  }
  defp to_result(type, values \\ [])
  defp to_result(%Type.NonNull{of_type: inner_type}, values) do
    to_result(inner_type, values)
  end
  defp to_result(nil, values) do
    struct(Blueprint.Document.Result.Leaf, values)
  end
  for {schema_module, result_module} <- @result_modules do
    defp to_result(%unquote(schema_module){}, values) do
      struct(unquote(result_module), values)
    end
  end

  defp walk_results(values, bp_root, bp_node, inner_type, info, acc \\ [])
  defp walk_results([], _, _, _, _, acc), do: :lists.reverse(acc)
  defp walk_results([value | values], bp_root, bp_node, inner_type, info, acc) do
    result = walk_result(value, bp_root, bp_node, inner_type, info)
    walk_results(values, bp_root, bp_node, inner_type, info, [result | acc])
  end

  def field_applies?(%{name: _, type_conditions: []}, _, _, _) do
    true
  end
  def field_applies?(field, bp_root, source, schema_type) do
    target_type = find_target_type(schema_type, bp_root.schema)
    value = field.type_conditions
    |> Enum.map(&(bp_root.schema.__absinthe_type__(&1.name)))
    |> Enum.all?(&passes_type_condition?(&1, target_type, source, bp_root.schema))
    value
  end

  def find_target_type(schema_type, schema) when is_atom(schema_type) do
    schema.__absinthe_type__(schema_type)
  end
  def find_target_type(%{type: type}, schema) do
    find_target_type(type, schema)
  end

  def error(node, message) do
    Phase.Error.new(
      __MODULE__,
      message,
      node.source_location
    )
  end

  @spec passes_type_condition?(Type.t, Type.t, any, Schema.t) :: boolean
  defp passes_type_condition?(equal, equal, _, _), do: true
  # The condition in an Object type and the current scope is a Union; Verify
  # that the Union has the Object type as a member.
  defp passes_type_condition?(%Type.Object{} = condition, %Type.Union{} = type, _, _) do
    Type.Union.member?(type, condition)
  end
  # The condition is an Object type and the current scope is an Interface; verify
  # that the Object type is a member of the Interface and that the current source
  # object's concrete type matched the condition Object type.
  defp passes_type_condition?(%Type.Object{} = condition, %Type.Interface{} = type, source, schema) do
    case Type.Interface.member?(type, condition) do
      true ->
        concrete_type = Type.Interface.resolve_type(type, source, %{schema: schema})
        passes_type_condition?(condition, concrete_type, source, schema)
      other ->
        other
    end
  end
  # The condition in an Interface type and the current scope is an Object type;
  # verify that the Object type is a member of the Interface.
  defp passes_type_condition?(%Type.Interface{} = condition, %Type.Object{} = type, _, _) do
    Type.Interface.member?(condition, type)
  end
  # Otherwise, nope.
  defp passes_type_condition?(_, _, _, _) do
    false
  end

end
