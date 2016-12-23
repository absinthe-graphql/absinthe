defmodule Absinthe.Phase.Document.Execution.Resolution do

  @moduledoc false

  # Runs resolution functions in a blueprint.
  #
  # Blueprint results are placed under `blueprint.result.resolution`. This is
  # because the results form basically a new tree from the original blueprint.

  alias Absinthe.{Blueprint, Type, Phase}
  alias Absinthe.Resolution.Plugin
  alias Blueprint.Document.Resolution

  alias Absinthe.Phase
  use Absinthe.Phase

  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(bp_root, options \\ []) do
    case Blueprint.current_operation(bp_root) do
      nil -> {:ok, bp_root}
      op -> resolve_current(bp_root, op, options)
    end
  end

  defp resolve_current(bp_root, operation, options) do
    resolution = perform_resolution(bp_root, operation, options)

    blueprint = %{bp_root | resolution: resolution}

    bp_root.schema.resolution_plugins
    |> Plugin.pipeline(resolution)
    |> case do
      [] ->
        {:ok, blueprint}
      pipeline ->
        {:insert, blueprint, pipeline}
    end
  end

  defp perform_resolution(bp_root, operation, options) do
    root_value = Keyword.get(options, :root_value, %{})

    info   = build_info(bp_root, root_value, options)
    acc    = bp_root.resolution.acc
    result = bp_root.resolution |> Resolution.get_result(operation, root_value)

    acc = bp_root.schema |> before_resolution(acc)

    {result, acc} = walk_result(result, acc, operation, operation.schema_node, info)

    acc = bp_root.schema |> after_resolution(acc)

    Resolution.update(bp_root.resolution, result, acc)
  end

  defp before_resolution(schema, acc) do
    schema.resolution_plugins |> Enum.reduce(acc, &(&1.before_resolution(&2)))
  end

  defp after_resolution(schema, acc) do
    schema.resolution_plugins |> Enum.reduce(acc, &(&1.after_resolution(&2)))
  end

  defp build_info(bp_root, root_value, options) do
    context = Keyword.get(options, :context, %{})

    %Absinthe.Resolution{
      adapter: bp_root.adapter,
      context: context,
      root_value: root_value,
      schema: bp_root.schema,
      source: root_value,
    }
  end

  @doc """
  This function walks through any existing results. If no results are found at a
  given node, it will call the requisite function to expand and build those results
  """
  def walk_result(%{fields: nil} = result, acc, bp_node, _schema_type, info) do
    {fields, acc} = resolve_fields(bp_node, acc, info, result.root_value)
    {%{result | fields: fields}, acc}
  end
  def walk_result(%{fields: fields} = result, acc, bp_node, schema_type, info) do
    {fields, acc} = walk_results(fields, acc, bp_node, schema_type, info)

    {%{result | fields: fields}, acc}
  end
  def walk_result(%Resolution.Leaf{} = result, acc, _, _, _) do
    {result, acc}
  end
  def walk_result(%{values: values} = result, acc, bp_node, schema_type, info) do
    {values, acc} = walk_results(values, acc, bp_node, schema_type, info)
    {%{result | values: values}, acc}
  end
  def walk_result(%Resolution.PluginInvocation{} = node, acc, _bp_node, _schema_type, _info) do
    {result, acc} = Resolution.PluginInvocation.resolve(node, acc)

    build_result(result, acc, node.emitter, node.info, node.source)
  end

  def resolve_field(bp_field, acc, info, source) do
    info = %{info | definition: bp_field}

    bp_field.argument_data
    |> call_resolution_function(bp_field, info, source)
    |> build_result(acc, bp_field, info, source)
  end

  defp resolve_fields(parent, acc, info, source) do
    parent_type = case parent.schema_node do
      %Type.Field{} = schema_node ->
        schema_node.type
        |> Type.unwrap
        |> info.schema.__absinthe_type__
      other ->
        other
    end
    info = %{info | parent_type: parent_type, source: source}

    parent.fields
    |> Enum.filter(&field_applies?(&1, info, source, parent.schema_node))
    # Conceptually just |> Enum.map(&resolve_field/n)
    |> do_resolve_fields(acc, info, source, [])
  end

  # mechanical function for optimized field walking, ignore
  defp do_resolve_fields(fields, res_acc, info, source, acc)
  defp do_resolve_fields([], res_acc, _, _, acc), do: {:lists.reverse(acc), res_acc}
  defp do_resolve_fields([%{schema_node: nil} | fields], res_acc, info, source, acc) do
    do_resolve_fields(fields, res_acc, info, source, acc)
  end
  defp do_resolve_fields([field | fields], res_acc, info, source, acc) do
    {result, res_acc} = resolve_field(field, res_acc, info, source)
    do_resolve_fields(fields, res_acc, info, source, [result | acc])
  end

  defp build_result({:ok, result}, acc, bp_field, info, _) do
    full_type = Type.expand(bp_field.schema_node.type, info.schema)

    result
    |> to_result(bp_field, full_type)
    |> walk_result(acc, bp_field, full_type, info)
  end
  ## Mutation resolver may return a response to update the context
  defp build_result({:ok, result, context}, acc, bp_field, info, source) do
    unless is_mutation?(info) do
      raise Absinthe.ExecutionError, """
      Only mutation resovers may return `{:ok, val, context}`
      Resolving field: #{bp_field.name}
      Resolving on: #{inspect source}
      Got: #{inspect {:ok, result, context}}
      """
    end
    build_result({:ok, result}, acc, bp_field, %{info | context: context}, source)
  end
  defp build_result({:error, params} = other, acc, bp_field, info, source) when is_list(params) or is_map(params) do
    case Keyword.split(Enum.to_list(params), [:message]) do
      {[], _} -> result_format_error(other, bp_field, source)
      {[message: msg], extra} ->
        build_error_result(msg, extra, acc, bp_field, info)
    end
  end
  defp build_result({:error, msg}, acc, bp_field, info, _) do
    build_error_result(msg, [], acc, bp_field, info)
  end
  defp build_result({:plugin, plugin, data}, acc, emitter, info, source) do
    Resolution.PluginInvocation.init(plugin, data, acc, emitter, info, source)
  end
  defp build_result(other, _, field, _, source) do
    result_format_error(other, field, source)
  end

  defp result_format_error(other, field, source) do
    raise Absinthe.ExecutionError, """
    Resolution function did not return `{:ok, term}`, `{:error, binary}` or `{:error, map | Keyword.t}`
    Resolving field: #{field.name}
    Resolving on: #{inspect source}
    Got: #{inspect other}
    """
  end

  defp build_error_result(message, extra, acc, bp_field, info) do
    message = ~s(In field "#{bp_field.name}": #{message})
    full_type = Type.expand(bp_field.schema_node.type, info.schema)

    result =
      nil
      |> to_result(bp_field, full_type)
      |> put_error(error(bp_field, message, extra))

    {result, acc}
  end

  defp is_mutation?(%Absinthe.Resolution{parent_type: %Type.Object{__reference__: %{identifier: :mutation}}}), do: true
  defp is_mutation?(_), do: false

  # Introspection Field
  defp call_resolution_function(args, %{schema_node: %{name: "__" <> _}} = field, info, _) do
    field.schema_node.resolve.(args, info)
  end
  # Interface/Union Field
  defp call_resolution_function(args, field, %{parent_type: %abstract_mod{}} = info, source)
      when abstract_mod in [Type.Interface, Type.Union] do
    concrete_type = abstract_mod.resolve_type(info.parent_type, source, info)
    # Try again, using the concrete type
    call_resolution_function(args, field, put_in(info.parent_type, concrete_type), source)
  end
  defp call_resolution_function(args, field, %{parent_type: %Type.Object{} = concrete_type} = info, source) do
    concrete_schema_node = Map.fetch!(concrete_type.fields, field.schema_node.__reference__.identifier)
    Type.Field.resolve(concrete_schema_node, args, source, info)
  end

  @spec to_result(resolution_result :: term, blueprint :: Blueprint.t, schema_type :: Type.t) :: Resolution.t
  defp to_result(nil, blueprint, %Type.NonNull{} = schema_type) do
    raise Absinthe.ExecutionError, nil_value_error(blueprint, schema_type)
  end
  defp to_result(nil, blueprint, _) do
    %Resolution.Leaf{emitter: blueprint, value: nil}
  end
  defp to_result(root_value, blueprint, %Type.NonNull{of_type: inner_type}) do
    to_result(root_value, blueprint, inner_type)
  end
  defp to_result(root_value, blueprint, %Type.Scalar{} = schema_type) do
    %Resolution.Leaf{
      emitter: blueprint,
      value: Type.Scalar.serialize(schema_type, root_value)
    }
  end
  defp to_result(root_value, blueprint, %Type.Enum{} = schema_type) do
    %Resolution.Leaf{
      emitter: blueprint,
      value: Type.Enum.serialize(schema_type, root_value)
    }
  end
  defp to_result(root_value, blueprint, %Type.Object{}) do
    %Resolution.Object{root_value: root_value, emitter: blueprint}
  end
  defp to_result(root_value, blueprint, %Type.Interface{}) do
    %Resolution.Object{root_value: root_value, emitter: blueprint}
  end
  defp to_result(root_value, blueprint, %Type.Union{}) do
    %Resolution.Object{root_value: root_value, emitter: blueprint}
  end
  defp to_result(root_value, blueprint, %Type.List{of_type: inner_type}) do
    values =
      root_value
      |> List.wrap
      |> Enum.map(&to_result(&1, blueprint, inner_type))

    %Resolution.List{values: values, emitter: blueprint}
  end

  defp walk_results(values, res_acc, bp_node, inner_type, info, acc \\ [])
  defp walk_results([], res_acc, _, _, _, acc), do: {:lists.reverse(acc), res_acc}
  defp walk_results([value | values], res_acc, bp_node, inner_type, info, acc) do
    {result, res_acc} = walk_result(value, res_acc, bp_node, inner_type, info)
    walk_results(values, res_acc, bp_node, inner_type, info, [result | acc])
  end

  def field_applies?(%{name: _, type_conditions: []}, _, _, _) do
    true
  end
  def field_applies?(field, info, source, schema_type) do
    target_type = find_target_type(schema_type, info.schema)

    field.type_conditions
    |> Enum.map(&info.schema.__absinthe_type__(&1.name))
    |> Enum.all?(&passes_type_condition?(&1, target_type, source, info.schema))
  end

  # For fields
  def find_target_type(%{type: type}, schema) do
    find_target_type(type, schema)
  end
  # For lists and non-nulls
  def find_target_type(%{of_type: type}, schema) do
    find_target_type(type, schema)
  end
  def find_target_type(schema_type, schema) when is_atom(schema_type) or is_binary(schema_type) do
    schema.__absinthe_type__(schema_type)
  end
  def find_target_type(type, _schema) do
    type
  end

  def error(node, message, extra \\ []) do
    Phase.Error.new(
      __MODULE__,
      message,
      location: node.source_location,
      extra: extra
    )
  end

  @spec passes_type_condition?(Type.t, Type.t, any, Schema.t) :: boolean
  defp passes_type_condition?(%{name: name}, %{name: name}, _, _), do: true
  # The condition is an Object type and the current scope is a Union; Verify
  # that the Union has the Object type as a member and that the current source
  # object's concrete type matched the condition Object type.
  defp passes_type_condition?(%Type.Object{} = condition, %Type.Union{} = type, source, schema) do
    with true <- Type.Union.member?(type, condition) do
      concrete_type = Type.Union.resolve_type(type, source, %{schema: schema})
      passes_type_condition?(condition, concrete_type, source, schema)
    end
  end
  # The condition is an Object type and the current scope is an Interface; verify
  # that the Object type is a member of the Interface and that the current source
  # object's concrete type matched the condition Object type.
  defp passes_type_condition?(%Type.Object{} = condition, %Type.Interface{} = type, source, schema) do
    with true <- Type.Interface.member?(type, condition) do
      concrete_type = Type.Interface.resolve_type(type, source, %{schema: schema})
      passes_type_condition?(condition, concrete_type, source, schema)
    end
  end
  # The condition is an Interface type and the current scope is an Object type;
  # verify that the Object type is a member of the Interface.
  defp passes_type_condition?(%Type.Interface{} = condition, %Type.Object{} = type, _, _) do
    Type.Interface.member?(condition, type)
  end
  # The condition is an Interface type and the current scope is an abstract
  # (Union/Interface) type; Verify that the current source object's concrete
  # type is a member of the Interface.
  defp passes_type_condition?(%Type.Interface{} = condition, %abstract_mod{} = type, source, schema)
      when abstract_mod in [Type.Interface, Type.Union] do
    concrete_type = Type.Union.resolve_type(type, source, %{schema: schema})
    passes_type_condition?(condition, concrete_type, source, schema)
  end
  # Otherwise, nope.
  defp passes_type_condition?(_, _, _, _) do
    false
  end

  defp nil_value_error(blueprint, _schema_type) do
    """
    The field '#{blueprint.name}' resolved to nil, but it is marked non-null in your schema.
    Please ensure that '#{blueprint.name}' always resolves to a non-null value.

    The corresponding Absinthe blueprint is:
    #{inspect blueprint}
    """
  end
end
