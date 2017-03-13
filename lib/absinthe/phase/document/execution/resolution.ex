defmodule Absinthe.Phase.Document.Execution.Resolution do

  @moduledoc false

  # Runs resolution functions in a blueprint.
  #
  # Blueprint results are placed under `blueprint.result.resolution`. This is
  # because the results form basically a new tree from the original blueprint.

  alias Absinthe.{Blueprint, Type, Phase}
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

    {:ok, blueprint}
  end

  defp perform_resolution(bp_root, operation, options) do
    root_value = Keyword.get(options, :root_value, %{})

    info   = build_info(bp_root, root_value, options)
    acc    = bp_root.resolution.acc
    result = bp_root.resolution |> Resolution.get_result(operation, root_value)

    {result, acc} = walk_result(result, acc, operation, operation.schema_node, info)

    Resolution.update(bp_root.resolution, result, acc)
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
  def walk_result(%Absinthe.Resolution{} = res, acc, _bp_node, _schema_type, info) do
    do_resolve_field(%{res | acc: acc}, info, res.source)
  end

  def resolve_field(bp_field, acc, %{parent_type: %Type.Interface{} = parent_type} = info, source) do
    resolve_abstract_field(bp_field, acc, info, source, parent_type)
  end
  def resolve_field(bp_field, acc, %{parent_type: %Type.Union{} = parent_type} = info, source) do
    resolve_abstract_field(bp_field, acc, info, source, parent_type)
  end
  def resolve_field(bp_field, acc, info, source) do
    info
    |> build_resolution_struct(bp_field, acc)
    |> do_resolve_field(info, source)
  end

  defp resolve_abstract_field(bp_field, acc, info, source, %abstract_mod{} = parent_type) do
    concrete_type = abstract_mod.resolve_type(parent_type, source, info)
    |> IO.inspect

    bp_field |> IO.inspect

    resolve_field(bp_field, acc, %{info | parent_type: concrete_type}, source)
  end

  defp build_resolution_struct(info, bp_field, acc) do
    %{info |
     middleware: bp_field.schema_node.middleware,
     acc: acc,
     definition: bp_field,
     arguments: bp_field.argument_data,
   }
  end

  # bp_field needs to have a concrete schema node, AKA no unions or interfaces
  defp do_resolve_field(res, info, source) do
    res
    |> reduce_resolution
    |> case do
      %{state: :resolved} = res ->
        build_result(res, info, source)

      %{state: :suspended} = res ->
        {res, res.acc}

      final_res ->
        raise """
        Should have halted or suspended middleware
        Started with: #{inspect res}
        Ended with: #{inspect final_res}
        """
    end
  end

  defp reduce_resolution(%{middleware: []} = res), do: res
  defp reduce_resolution(%{middleware: [middleware | remaining_middleware]} = res) do
    case call_middleware(middleware, %{res | middleware: remaining_middleware}) do
      %{state: :suspended} = res ->
        res
      res ->
        reduce_resolution(res)
    end
  end

  defp call_middleware({{mod, fun}, opts}, res) do
    apply(mod, fun, [res, opts])
  end
  defp call_middleware({mod, opts}, res) do
    apply(mod, :call, [res, opts])
  end
  defp call_middleware(mod, res) when is_atom(mod) do
    apply(mod, :call, [res, []])
  end
  defp call_middleware(fun, res) when is_function(fun, 2) do
    fun.(res, [])
  end

  defp build_result(%{errors: [], value: result} = res, info, _source) do
    # full_type = Type.expand(res.definition.schema_node.type, info.schema)
    full_type = res.definition.schema_node.type
    bp_field = res.definition

    info = if res.context == info.context do
      info
    else
      %{info | context: res.context}
    end

    result
    |> to_result(bp_field, full_type)
    |> walk_result(res.acc, bp_field, full_type, info)
  end
  defp build_result(%{errors: errors} = res, info, source) do
    build_error_result({:error, errors}, errors, res.acc, res.definition, info, source)
  end

  defp get_return_type(%{schema_node: %Type.Field{type: type}}) do
    Type.unwrap(type)
  end
  defp get_return_type(type), do: type

  defp handle_abstract_types(%abstract_mod{} = parent_type, source, info) when abstract_mod in [Type.Interface, Type.Union] do
    abstract_mod.resolve_type(parent_type, source, info)
  end
  defp handle_abstract_types(parent_type, _source, _info) do
    parent_type
  end

  defp resolve_fields(parent, acc, info, source) do
    parent_type =
      parent
      # parent is the parent field, we need to get the return type of that field
      |> get_return_type
      # that return type could be an interface or union, so let's make it concrete
      |> handle_abstract_types(source, info)

    info = %{info | parent_type: parent_type, source: source}

    do_resolve_fields(parent.fields, acc, info, source, parent_type, [])
  end

  defp do_resolve_fields(fields, res_acc, info, source, parent_type, acc)
  defp do_resolve_fields([], res_acc, _, _, _, acc), do: {:lists.reverse(acc), res_acc}
  defp do_resolve_fields([%{schema_node: nil} | fields], res_acc, info, source, parent_type, acc) do
    do_resolve_fields(fields, res_acc, info, source, parent_type, acc)
  end
  defp do_resolve_fields([field | fields], res_acc, info, source, parent_type, acc) do
    case field_applies?(parent_type, field) do
      true ->
        {result, res_acc} = resolve_field(field, res_acc, info, source)
        do_resolve_fields(fields, res_acc, info, source, parent_type, [result | acc])
      false ->
        do_resolve_fields(fields, res_acc, info, source, parent_type, acc)
    end
  end

  defp build_error_result(original_value, error_values, acc, bp_field, info, source) do
    full_type = Type.expand(bp_field.schema_node.type, info.schema)
    result = to_result(nil, bp_field, full_type)
    result = Enum.reduce(Enum.reverse(error_values), result, &put_result_error_value(&1, &2, original_value, bp_field, source))
    {result, acc}
  end

  defp put_result_error_value(error_value, result, original_value, bp_field, source) do
    case split_error_value(error_value) do
      {[], _} ->
        raise Absinthe.Resolution.result_error(original_value, bp_field, source)
      {[message: message], extra} ->
        message = ~s(In field "#{bp_field.name}": #{message})
        put_error(result, error(bp_field, message, extra))
    end
  end

  defp split_error_value(error_value) when is_list(error_value) or is_map(error_value) do
    Keyword.split(Enum.to_list(error_value), [:message])
  end
  defp split_error_value(error_value) when is_binary(error_value) do
    {[message: error_value], []}
  end
  defp split_error_value(error_value) do
    {[message: to_string(error_value)], []}
  end

  @spec to_result(resolution_result :: term, blueprint :: Blueprint.Document.Field.t, schema_type :: Type.t) ::
    Resolution.node_t
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

  def field_applies?(parent_type, %{type_conditions: conditions}) do
    do_field_applies?(conditions, parent_type, true)
  end

  defp do_field_applies?(_, _, false), do: false
  defp do_field_applies?([], parent_type, acc) do
    acc
  end
  defp do_field_applies?([condition | conditions], parent_type, _) do
    do_field_applies?(conditions, parent_type, passes_type_condition?(condition, parent_type))
  end

  defp passes_type_condition?(%Type.Object{name: name}, %Type.Object{name: name}) do
    true
  end
  defp passes_type_condition?(%Type.Interface{} = condition, %Type.Object{} = type) do
    Type.Interface.member?(condition, type)
  end
  defp passes_type_condition?(%Type.Union{} = condition, %Type.Object{} = type) do
    Type.Union.member?(condition, type)
  end
  defp passes_type_condition?(_, _) do
    false
  end

  def error(node, message, extra \\ []) do
    Phase.Error.new(
      __MODULE__,
      message,
      location: node.source_location,
      extra: extra
    )
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
