defmodule Absinthe.Phase.Document.Execution.Resolution2 do
  @moduledoc false

  # Runs resolution functions in a blueprint.
  #
  # Blueprint results are placed under `blueprint.result.execution`. This is
  # because the results form basically a new tree from the original blueprint.

  alias Absinthe.{Blueprint, Type, Phase}
  alias Blueprint.{Result, Execution}

  alias Absinthe.Phase
  use Absinthe.Phase

  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
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

    result = exec.result |> Map.put(:ref, cut_ref())

    stack = [{:result, :top, result}]

    stack = push(stack, result.emitter.selections, result)

    {result, exec} = resolve(stack, [], exec)

    %{exec | result: result}
  end

  defp push(stack, [], _) do
    stack
  end

  defp push(stack, [field | fields], parent) do
    push([{:field, parent, field} | stack], fields, parent)
  end

  defp run_callbacks(plugins, callback, acc, true) do
    Enum.reduce(plugins, acc, &apply(&1, callback, [&2]))
  end

  defp run_callbacks(_, _, acc, _), do: acc

  defp resolve([], result, exec) do
    {result, exec}
  end

  defp resolve([{:result, _, _} = result | rest], results, exec) do
    resolve(rest, [result | results], exec)
  end

  defp resolve([{:field, parent, field} | stack], results, exec) do
    {stack, exec} = resolve_field(stack, exec, parent, [], field)
    resolve(stack, results, exec)
  end

  def resolve_field(stack, exec, parent, path, field) do
    res =
      build_resolution_struct(exec, field, parent.root_value, parent.emitter.schema_node, path)

    do_resolve_field(stack, exec, parent, path, res)
  end

  # bp_field needs to have a concrete schema node, AKA no unions or interfaces
  defp do_resolve_field(stack, exec, parent, path, res) do
    res
    |> reduce_resolution
    |> case do
      %{state: :resolved} = res ->
        exec = update_persisted_fields(exec, res)
        build_result(stack, exec, parent, path, res)

      %{state: :suspended} = res ->
        exec = update_persisted_fields(exec, res)
        {res, exec}

      final_res ->
        raise """
        Should have halted or suspended middleware
        Started with: #{inspect(res)}
        Ended with: #{inspect(final_res)}
        """
    end
  end

  defp update_persisted_fields(dest, %{acc: acc, context: context, fields_cache: cache}) do
    %{dest | acc: acc, context: context, fields_cache: cache}
  end

  defp build_resolution_struct(exec, bp_field, source, parent_type, path) do
    common =
      Map.take(exec, [:adapter, :context, :acc, :root_value, :schema, :fragments, :fields_cache])

    %Absinthe.Resolution{
      path: path,
      source: source,
      parent_type: parent_type,
      middleware: bp_field.schema_node.middleware,
      definition: bp_field,
      arguments: bp_field.argument_data
    }
    |> Map.merge(common)
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

  defp build_result(stack, exec, parent, path, %{errors: errors} = res) do
    %{
      value: value,
      definition: bp_field,
      extensions: extensions
    } = res

    full_type = Type.expand(bp_field.schema_node.type, exec.schema)

    bp_field = put_in(bp_field.schema_node.type, full_type)

    # if there are any errors, the value is always nil
    value =
      case errors do
        [] -> value
        _ -> nil
      end

    errors = maybe_add_non_null_error(errors, value, full_type)

    result = to_result(value, bp_field, parent.ref, full_type, extensions)
    next_work(stack, exec, result)
  end

  defp maybe_add_non_null_error(errors, nil, %Type.NonNull{}) do
    ["Cannot return null for non-nullable field" | errors]
  end

  defp maybe_add_non_null_error(errors, _, _) do
    errors
  end

  defp propagate_null_trimming({%{values: values} = node, exec}) do
    values = Enum.map(values, &do_propagate_null_trimming/1)
    node = %{node | values: values}
    {do_propagate_null_trimming(node), exec}
  end

  defp propagate_null_trimming({node, exec}) do
    {do_propagate_null_trimming(node), exec}
  end

  defp do_propagate_null_trimming(node) do
    if bad_child = find_bad_child(node) do
      bp_field = node.emitter

      full_type =
        with %{type: type} <- bp_field.schema_node do
          type
        end

      nil
      # |> to_result(bp_field, full_type, node.extensions)
      # |> Map.put(:errors, bad_child.errors)

      # ^ We don't have to worry about clobbering the current node's errors because,
      # if it had any errors, it wouldn't have any children and we wouldn't be
      # here anyway.
    else
      node
    end
  end

  defp find_bad_child(%{fields: fields}) do
    Enum.find(fields, &non_null_violation?/1)
  end

  defp find_bad_child(%{values: values}) do
    Enum.find(values, &non_null_list_violation?/1)
  end

  defp find_bad_child(_) do
    false
  end

  # FIXME: Not super happy with this lookup process
  defp non_null_violation?(%{value: nil, emitter: %{schema_node: %{type: %Type.NonNull{}}}}) do
    true
  end

  defp non_null_violation?(_) do
    false
  end

  # FIXME: Not super happy with this lookup process.
  # Also it would be nice if we could use the same function as above.
  defp non_null_list_violation?(%{
         value: nil,
         emitter: %{schema_node: %{type: %Type.List{of_type: %Type.NonNull{}}}}
       }) do
    true
  end

  defp non_null_list_violation?(_) do
    false
  end

  # defp maybe_add_non_null_error(errors, nil, %)

  defp add_errors(result, errors, fun) do
    Enum.reduce(errors, result, fun)
  end

  defp put_result_error_value(error_value, result, bp_field, source, path) do
    case split_error_value(error_value) do
      {[], _} ->
        raise Absinthe.Resolution.result_error(error_value, bp_field, source)

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

  defp to_result(stack, nil, blueprint, parent_ref, _, extensions) do
    [
      {:result, parent_ref, %Result.Leaf{emitter: blueprint, value: nil, extensions: extensions}}
      | stack
    ]
  end

  defp to_result(
         stack,
         root_value,
         blueprint,
         parent_ref,
         %Type.NonNull{of_type: inner_type},
         extensions
       ) do
    to_result(stack, root_value, blueprint, parent_ref, inner_type, extensions)
  end

  defp to_result(stack, root_value, blueprint, parent_ref, %Type.Object{}, extensions) do
    result = %Result.Object{
      root_value: root_value,
      emitter: blueprint,
      extensions: extensions,
      ref: cut_ref()
    }

    stack = [{:result, parent_ref, result} | stack]

    push(stack, blueprint.selections, result)
  end

  # defp to_result(root_value, blueprint, parent_ref, %Type.Interface{}, extensions) do
  #   result = %Result.Object{
  #     root_value: root_value,
  #     emitter: blueprint,
  #     extensions: extensions,
  #     ref: cut_ref()
  #   }

  #   fields = blueprint.selections |> queue(result)

  #   [
  #     {:result, parent_ref, result}
  #     | fields
  #   ]
  # end

  # defp to_result(root_value, blueprint, parent_ref, %Type.Union{}, extensions) do
  #   result = %Result.Object{
  #     root_value: root_value,
  #     emitter: blueprint,
  #     extensions: extensions,
  #     ref: cut_ref()
  #   }

  #   fields = blueprint.selections |> queue(result)

  #   [
  #     {:result, parent_ref, result}
  #     | fields
  #   ]
  # end

  defp to_result(
         stack,
         root_value,
         blueprint,
         parent_ref,
         %Type.List{of_type: inner_type},
         extensions
       ) do
    list = %Result.List{values: nil, emitter: blueprint, extensions: extensions, ref: cut_ref()}

    stack = [{:result, parent_ref, list} | stack]

    to_result(stack, List.wrap(root_value), )

    values =
      root_value
      |> List.wrap()
      |> Enum.flat_map(&to_result(&1, blueprint, list.ref, inner_type, extensions))

    [{:result, parent_ref, list} | values] ++ stack
  end

  defp to_result(stack, root_value, blueprint, parent_ref, %Type.Scalar{}, extensions) do
    [
      {:result, parent_ref,
       %Result.Leaf{
         emitter: blueprint,
         value: root_value,
         extensions: extensions
       }}
      | stack
    ]
  end

  defp to_result(stack, root_value, blueprint, parent_ref, %Type.Enum{}, extensions) do
    [
      {:result, parent_ref,
       %Result.Leaf{
         emitter: blueprint,
         value: root_value,
         extensions: extensions
       }}
      | stack
    ]
  end

  defp list_result(stack, items, parent_ref, extensions) do

  end

  def error(node, message, path, extra) do
    %Phase.Error{
      phase: __MODULE__,
      message: message,
      locations: [node.source_location],
      path: Absinthe.Resolution.path(%{path: path}),
      extra: extra
    }
  end

  defp cut_ref() do
    :erlang.unique_integer([:positive, :monotonic])
  end
end
