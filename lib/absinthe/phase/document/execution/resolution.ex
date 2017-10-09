defmodule Absinthe.Phase.Document.Execution.Resolution do

  @moduledoc false

  # Runs resolution functions in a blueprint.
  #
  # Blueprint results are placed under `blueprint.result.execution`. This is
  # because the results form basically a new tree from the original blueprint.

  alias Absinthe.{Blueprint, Type, Phase}
  alias Blueprint.{Result, Execution}

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
    execution = perform_resolution(bp_root, operation, options)

    blueprint = %{bp_root | execution: execution}

    if Keyword.get(options, :plugin_callbacks, true) do
      bp_root.schema.plugins()
      |> Absinthe.Plugin.pipeline(execution)
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
    exec = Execution.get(bp_root, operation)

    plugins = bp_root.schema.plugins()
    run_callbacks? = Keyword.get(options, :plugin_callbacks, true)

    exec = plugins |> run_callbacks(:before_resolution, exec, run_callbacks?)

    {result, exec} = walk_result(exec.result, operation, operation.schema_node, exec, [operation])

    exec = plugins |> run_callbacks(:after_resolution, exec, run_callbacks?)

    %{exec | result: result}
  end

  defp run_callbacks(plugins, callback, acc, true) do
    Enum.reduce(plugins, acc, &apply(&1, callback, [&2]))
  end
  defp run_callbacks(_, _, acc, _ ), do: acc

  @doc """
  This function walks through any existing results. If no results are found at a
  given node, it will call the requisite function to expand and build those results
  """
  def walk_result(%{fields: nil} = result, bp_node, _schema_type, exec, path) do
    {fields, exec} = resolve_fields(bp_node, exec, result.root_value, path)
    {%{result | fields: fields}, exec}
  end
  def walk_result(%{fields: fields} = result, bp_node, schema_type, exec, path) do
    {fields, exec} = walk_results(fields, bp_node, schema_type, exec, [0 | path], [])

    {%{result | fields: fields}, exec}
  end
  def walk_result(%Result.Leaf{} = result, _, _, exec, _) do
    {result, exec}
  end
  def walk_result(%{values: values} = result, bp_node, schema_type, exec, path) do
    {values, exec} = walk_results(values, bp_node, schema_type, exec, [0 | path], [])
    {%{result | values: values}, exec}
  end
  def walk_result(%Absinthe.Resolution{} = res, _bp_node, _schema_type, exec, _path) do
    res = update_persisted_fields(res, exec)
    do_resolve_field(res, exec, res.source, res.path)
  end

  # walk list results
  defp walk_results([value | values], bp_node, inner_type, exec, [i | sub_path] = path, acc) do
    {result, exec} = walk_result(value, bp_node, inner_type, exec, path)
    walk_results(values, bp_node, inner_type, exec, [i + 1 | sub_path], [result | acc])
  end
  defp walk_results([], _, _, exec, _, acc), do: {:lists.reverse(acc), exec}

  defp resolve_fields(parent, exec, source, path) do
    parent
    # parent is the parent field, we need to get the return type of that field
    |> get_return_type
    # that return type could be an interface or union, so let's make it concrete
    |> get_concrete_type(source, exec)
    |> case do
      nil ->
        {[], exec}
      parent_type ->
        {fields, fields_cache} = Absinthe.Resolution.Projector.project(parent.selections, parent_type, path, exec.fields_cache, exec)

        exec = %{exec | fields_cache: fields_cache}

        do_resolve_fields(fields, exec, source, parent_type, path, [])
    end
  end

  defp get_return_type(%{schema_node: %Type.Field{type: type}}) do
    Type.unwrap(type)
  end
  defp get_return_type(%{schema_node: schema_node}) do
    Type.unwrap(schema_node)
  end
  defp get_return_type(type), do: type

  defp get_concrete_type(%Type.Union{} = parent_type, source, exec) do
    Type.Union.resolve_type(parent_type, source, exec)
  end
  defp get_concrete_type(%Type.Interface{} = parent_type, source, exec) do
    Type.Interface.resolve_type(parent_type, source, exec)
  end
  defp get_concrete_type(parent_type, _source, _exec) do
    parent_type
  end

  defp do_resolve_fields([field | fields], exec, source, parent_type, path, acc) do
    {result, exec} = resolve_field(field, exec, source, parent_type, [field | path])
    do_resolve_fields(fields, exec, source, parent_type, path, [result | acc])
  end
  defp do_resolve_fields([], exec, _, _, _, acc), do: {:lists.reverse(acc), exec}

  def resolve_field(field, exec, source, parent_type, path) do
    exec
    |> build_resolution_struct(field, source, parent_type, path)
    |> do_resolve_field(exec, source, path)
  end

  # bp_field needs to have a concrete schema node, AKA no unions or interfaces
  defp do_resolve_field(res, exec, source, path) do
    res
    |> reduce_resolution
    |> case do
      %{state: :resolved} = res ->
        exec = update_persisted_fields(exec, res)
        build_result(res, exec, source, path)

      %{state: :suspended} = res ->
        exec = update_persisted_fields(exec, res)
        {res, exec}

      final_res ->
        raise """
        Should have halted or suspended middleware
        Started with: #{inspect res}
        Ended with: #{inspect final_res}
        """
    end
  end


  defp update_persisted_fields(dest, %{acc: acc, context: context, fields_cache: cache}) do
    %{dest | acc: acc, context: context, fields_cache: cache}
  end

  defp build_resolution_struct(exec, bp_field, source, parent_type, path) do
    common = Map.take(exec, [:adapter, :context, :acc, :root_value, :schema, :fragments, :fields_cache])
    %Absinthe.Resolution{
      path: path,
      source: source,
      parent_type: parent_type,
      middleware: bp_field.schema_node.middleware,
      definition: bp_field,
      arguments: bp_field.argument_data,
    } |> Map.merge(common)
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

  defp build_result(%{errors: []} = res, exec, _source, path) do
    %{
      value: result,
      definition: bp_field,
      extensions: extensions
    } = res

    full_type = Type.expand(bp_field.schema_node.type, exec.schema)

    bp_field = put_in(bp_field.schema_node.type, full_type)

    result = result |> to_result(bp_field, full_type)

    %{result | extensions: extensions}
    |> walk_result(bp_field, full_type, exec, path)
  end
  defp build_result(%{errors: errors} = res, exec, source, path) do
    build_error_result({:error, errors}, errors, res.definition, exec, source, path)
  end

  defp build_error_result(original_value, error_values, bp_field, exec, source, path) do
    full_type = Type.expand(bp_field.schema_node.type, exec.schema)
    result = to_result(nil, bp_field, full_type)
    result = Enum.reduce(Enum.reverse(error_values), result, &put_result_error_value(&1, &2, original_value, bp_field, source, path))
    {result, exec}
  end

  defp put_result_error_value(error_value, result, original_value, bp_field, source, path) do
    case split_error_value(error_value) do
      {[], _} ->
        raise Absinthe.Resolution.result_error(original_value, bp_field, source)
      {[message: message], extra} ->
        put_error(result, error(bp_field, message, path, Map.new(extra)))
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
    Result.node_t
  defp to_result(nil, blueprint, %Type.NonNull{} = schema_type) do
    raise Absinthe.ExecutionError, nil_value_error(blueprint, schema_type)
  end
  defp to_result(nil, blueprint, _) do
    %Result.Leaf{emitter: blueprint, value: nil}
  end
  defp to_result(root_value, blueprint, %Type.NonNull{of_type: inner_type}) do
    to_result(root_value, blueprint, inner_type)
  end
  defp to_result(root_value, blueprint, %Type.Object{}) do
    %Result.Object{root_value: root_value, emitter: blueprint}
  end
  defp to_result(root_value, blueprint, %Type.Interface{}) do
    %Result.Object{root_value: root_value, emitter: blueprint}
  end
  defp to_result(root_value, blueprint, %Type.Union{}) do
    %Result.Object{root_value: root_value, emitter: blueprint}
  end
  defp to_result(root_value, blueprint, %Type.List{of_type: inner_type}) do
    values =
      root_value
      |> List.wrap
      |> Enum.map(&to_result(&1, blueprint, inner_type))

    %Result.List{values: values, emitter: blueprint}
  end
  defp to_result(root_value, blueprint, %Type.Scalar{}) do
    %Result.Leaf{
      emitter: blueprint,
      value: root_value,
    }
  end
  defp to_result(root_value, blueprint, %Type.Enum{}) do
    %Result.Leaf{
      emitter: blueprint,
      value: root_value,
    }
  end

  def error(node, message, path, extra) do
    %Phase.Error{
      phase: __MODULE__,
      message: message,
      locations: [node.source_location],
      path: Absinthe.Resolution.path(%{path: path}),
      extra: extra,
    }
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
