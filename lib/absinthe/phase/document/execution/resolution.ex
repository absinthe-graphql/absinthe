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

    if Keyword.get(options, :plugin_callbacks, true) do
      bp_root.schema.plugins()
      |> Absinthe.Plugin.pipeline(resolution.acc)
      |> case do
        [] ->
          {:ok, blueprint}
        pipeline ->
          {:insert, blueprint, pipeline}
      end
    else
      {:ok, blueprint}
    end
  end

  defp perform_resolution(bp_root, operation, options) do
    root_value = bp_root.resolution.root_value

    info   = build_info(bp_root, root_value)
    acc    = bp_root.resolution.acc
    result = bp_root.resolution |> Resolution.get_result(operation, root_value)

    plugins = bp_root.schema.plugins()
    run_callbacks? = Keyword.get(options, :plugin_callbacks, true)

    acc = plugins |> run_callbacks(:before_resolution, acc, run_callbacks?)

    info = %{info | acc: acc}

    {result, info} = walk_result(result, operation, operation.schema_node, info, [operation])

    acc = plugins |> run_callbacks(:after_resolution, info.acc, run_callbacks?)

    Resolution.update(bp_root.resolution, result, acc)
  end

  defp run_callbacks(plugins, callback, acc, true) do
    Enum.reduce(plugins, acc, &apply(&1, callback, [&2]))
  end
  defp run_callbacks(_, _, acc, _ ), do: acc

  defp build_info(bp_root, root_value) do
    context = bp_root.resolution.context

    %Absinthe.Resolution{
      adapter: bp_root.adapter,
      context: context,
      root_value: root_value,
      schema: bp_root.schema,
      source: root_value,
      fragments: Map.new(bp_root.fragments, &{&1.name, &1}),
    }
  end

  @doc """
  This function walks through any existing results. If no results are found at a
  given node, it will call the requisite function to expand and build those results
  """
  def walk_result(%{fields: nil} = result, bp_node, _schema_type, info, path) do
    {fields, info} = resolve_fields(bp_node, info, result.root_value, path)
    {%{result | fields: fields}, info}
  end
  def walk_result(%{fields: fields} = result, bp_node, schema_type, info, path) do
    {fields, info} = walk_results(fields, bp_node, schema_type, info, path, [])

    {%{result | fields: fields}, info}
  end
  def walk_result(%Resolution.Leaf{} = result, _, _, info, _) do
    {result, info}
  end
  def walk_result(%{values: values} = result, bp_node, schema_type, info, path) do
    {values, info} = walk_results(values, bp_node, schema_type, info, path, [])
    {%{result | values: values}, info}
  end
  def walk_result(%Absinthe.Resolution{} = res, _bp_node, _schema_type, info, _path) do
    do_resolve_field(%{res | acc: info.acc}, info, res.source, res.path)
  end

  # walk list results
  defp walk_results([value | values], bp_node, inner_type, info, path, acc) do
    {result, info} = walk_result(value, bp_node, inner_type, info, path)
    walk_results(values, bp_node, inner_type, info, path, [result | acc])
  end
  defp walk_results([], _, _, info, _, acc), do: {:lists.reverse(acc), info}

  defp resolve_fields(parent, info, source, path) do
    parent_type =
      parent
      # parent is the parent field, we need to get the return type of that field
      |> get_return_type
      # that return type could be an interface or union, so let's make it concrete
      |> get_concrete_type(source, info)

    {fields, fields_cache} = Absinthe.Resolution.Projector.project(parent.selections, parent_type, path, info.fields_cache, info)

    info = %{info | fields_cache: fields_cache}

    do_resolve_fields(fields, info, source, parent_type, path, [])
  end

  defp get_return_type(%{schema_node: %Type.Field{type: type}}) do
    Type.unwrap(type)
  end
  defp get_return_type(%{schema_node: schema_node}) do
    Type.unwrap(schema_node)
  end
  defp get_return_type(type), do: type

  defp get_concrete_type(%Type.Union{} = parent_type, source, info) do
    Type.Union.resolve_type(parent_type, source, info)
  end
  defp get_concrete_type(%Type.Interface{} = parent_type, source, info) do
    Type.Interface.resolve_type(parent_type, source, info)
  end
  defp get_concrete_type(parent_type, _source, _info) do
    parent_type
  end

  defp do_resolve_fields([field | fields], info, source, parent_type, path, acc) do
    {result, info} = resolve_field(field, info, source, parent_type, [field | path])
    do_resolve_fields(fields, info, source, parent_type, path, [result | acc])
  end
  defp do_resolve_fields([], info, _, _, _, acc), do: {:lists.reverse(acc), info}

  def resolve_field(field, info, source, parent_type, path) do
    info
    |> build_resolution_struct(field, source, parent_type, path)
    |> do_resolve_field(info, source, path)
  end

  # bp_field needs to have a concrete schema node, AKA no unions or interfaces
  defp do_resolve_field(res, info, source, path) do
    res
    |> reduce_resolution
    |> case do
      %{state: :resolved} = res ->
        build_result(res, info, source, path)

      %{state: :suspended, acc: acc} = res ->
        {res, %{info | acc: acc}}

      final_res ->
        raise """
        Should have halted or suspended middleware
        Started with: #{inspect res}
        Ended with: #{inspect final_res}
        """
    end
  end

  defp build_resolution_struct(info, bp_field, source, parent_type, path) do
    %{info |
      path: path,
      source: source,
      parent_type: parent_type,
      middleware: bp_field.schema_node.middleware,
      definition: bp_field,
      arguments: bp_field.argument_data,
    }
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

  defp build_result(%{errors: []} = res, info, _source, path) do
    %{
      value: result,
      context: context,
      acc: acc,
      definition: bp_field,
      extensions: extensions
    } = res

    full_type = Type.expand(bp_field.schema_node.type, info.schema)

    bp_field = put_in(bp_field.schema_node.type, full_type)

    info = %{info | context: context, acc: acc}

    result = result |> to_result(bp_field, full_type)

    %{result | extensions: extensions}
    |> walk_result(bp_field, full_type, info, path)
  end
  defp build_result(%{errors: errors} = res, info, source, _path) do
    build_error_result({:error, errors}, errors, res.acc, res.definition, info, source)
  end

  defp build_error_result(original_value, error_values, acc, bp_field, info, source) do
    info = %{info | acc: acc}
    full_type = Type.expand(bp_field.schema_node.type, info.schema)
    result = to_result(nil, bp_field, full_type)
    result = Enum.reduce(Enum.reverse(error_values), result, &put_result_error_value(&1, &2, original_value, bp_field, source))
    {result, info}
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
  defp to_result(root_value, blueprint, %Type.Scalar{}) do
    %Resolution.Leaf{
      emitter: blueprint,
      value: root_value,
    }
  end
  defp to_result(root_value, blueprint, %Type.Enum{}) do
    %Resolution.Leaf{
      emitter: blueprint,
      value: root_value,
    }
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
