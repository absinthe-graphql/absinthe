defmodule Absinthe.Phase.Document.Execution.Resolution do
  @moduledoc false

  # Runs resolution functions in a blueprint.
  #
  # Blueprint results are placed under `blueprint.result.execution`. This is
  # because the results form basically a new tree from the original blueprint.
  #
  # The first run of this phase walks the operation and builds the result tree.
  # Fields that suspend (async, batch, dataloader) leave a
  # `%Result.Pending{ref: ref}` placeholder in the tree; the suspended
  # `%Absinthe.Resolution{}` structs are collected in a flat pool under
  # `execution.pending`. Subsequent runs of this phase iterate only that pool —
  # the already-built result tree is not re-walked. Results of resumed fields
  # (which may themselves contain new placeholders) accumulate in
  # `execution.resolved`, keyed by ref. Once the pool is empty, placeholders
  # are replaced by their results in a single substitution pass that also
  # applies non-null propagation along the substituted paths.

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

    exec = plugins |> run_callbacks(:before_resolution, exec, run_callbacks?)

    common =
      Map.take(exec, [:adapter, :context, :acc, :root_value, :schema, :fragments, :fields_cache])

    res =
      %Absinthe.Resolution{
        path: nil,
        source: nil,
        parent_type: nil,
        middleware: nil,
        definition: nil,
        arguments: nil
      }
      |> Map.merge(common)

    exec = do_perform_resolution(exec, operation, res)

    exec = plugins |> run_callbacks(:after_resolution, exec, run_callbacks?)

    maybe_substitute_pending(exec)
  end

  # First run: expand the operation into the result tree. Suspended fields
  # leave placeholders in the tree and are collected into the pending pool.
  defp do_perform_resolution(%{result: %{fields: nil}} = exec, operation, res) do
    {result, res} =
      exec.result
      |> walk_result(operation, operation.schema_node, res, [operation])
      |> propagate_null_trimming

    exec = update_persisted_fields(exec, res)

    %{exec | result: result, pending: Enum.reverse(res.pending)}
  end

  # Subsequent runs: resume only the suspended fields in the pending pool. The
  # result tree already built in previous runs is left untouched; completed
  # results are stored by ref for the final substitution pass.
  defp do_perform_resolution(exec, _operation, res) do
    {pool, resolved, res} =
      Enum.reduce(exec.pending, {[], exec.resolved, res}, &resolve_pending/2)

    exec = update_persisted_fields(exec, res)

    %{exec | pending: Enum.reverse(pool, Enum.reverse(res.pending)), resolved: resolved}
  end

  defp resolve_pending({ref, old_res}, {pool, resolved, res}) do
    res = update_persisted_fields(old_res, res)

    res
    |> reduce_resolution
    |> case do
      %{state: :resolved} = res ->
        {result, res} = build_result(res, res.source, res.path)
        {pool, Map.put(resolved, ref, result), res}

      %{state: :suspended} = suspended_res ->
        pool = [{ref, %{suspended_res | pending: []}} | pool]
        {pool, resolved, update_persisted_fields(res, suspended_res)}

      final_res ->
        raise """
        Should have halted or suspended middleware
        Started with: #{inspect(res)}
        Ended with: #{inspect(final_res)}
        """
    end
  end

  # Once nothing remains suspended, splice the resolved results in over their
  # placeholders. This is the only walk of the existing tree that re-running
  # this phase performs, and it happens exactly once per document.
  defp maybe_substitute_pending(%{pending: [], resolved: resolved} = exec)
       when map_size(resolved) > 0 do
    {result, _} = substitute(exec.result, resolved)
    %{exec | result: result, resolved: %{}}
  end

  defp maybe_substitute_pending(exec), do: exec

  defp substitute(%Result.Pending{ref: ref}, resolved) do
    {node, _} = substitute(Map.fetch!(resolved, ref), resolved)
    {node, true}
  end

  defp substitute(%Result.Object{fields: fields} = node, resolved) do
    case substitute_all(fields, resolved) do
      {_, false} ->
        {node, false}

      {fields, true} ->
        {do_propagate_null_trimming(%{node | fields: fields}), true}
    end
  end

  defp substitute(%Result.List{values: values} = node, resolved) do
    case substitute_all(values, resolved) do
      {_, false} ->
        {node, false}

      {values, true} ->
        values = Enum.map(values, &do_propagate_null_trimming/1)
        {do_propagate_null_trimming(%{node | values: values}), true}
    end
  end

  defp substitute(node, _resolved), do: {node, false}

  defp substitute_all(nodes, resolved) do
    Enum.map_reduce(nodes, false, fn node, changed ->
      {node, node_changed} = substitute(node, resolved)
      {node, changed or node_changed}
    end)
  end

  defp run_callbacks(plugins, callback, acc, true) do
    Enum.reduce(plugins, acc, &apply(&1, callback, [&2]))
  end

  defp run_callbacks(_, _, acc, _), do: acc

  @doc """
  This function builds the results under a given node. Any suspended fields
  encountered leave a `%Result.Pending{}` placeholder and are accumulated on
  the resolution struct's `:pending` list.
  """
  # Note: `root_value` must stay on the built object even though this phase no
  # longer needs it — downstream result phases can consume it (e.g.
  # Absinthe.Phoenix.Controller.Result returns raw source values for objects
  # without subselections and merges them for `@put`).
  def walk_result(%Result.Object{fields: nil} = result, bp_node, _schema_type, res, path) do
    {fields, res} = resolve_fields(bp_node, res, result.root_value, path)
    {%{result | fields: fields}, res}
  end

  def walk_result(%Result.Leaf{} = result, _, _, res, _) do
    {result, res}
  end

  # Compact scalar/enum list: its raw values have no fields to resolve.
  def walk_result(%Result.LeafList{} = result, _, _, res, _) do
    {result, res}
  end

  def walk_result(%Result.List{values: values} = result, bp_node, schema_type, res, path) do
    {values, res} = walk_results(values, bp_node, schema_type, res, [0 | path], [])
    {%{result | values: values}, res}
  end

  # Walk list results. The element path is threaded as an argument rather than
  # written to `res` (which would copy the struct once per element). Only Union
  # and Interface `resolve_type` callbacks read the path off `res`;
  # `get_concrete_type` sets it there right before invoking them.
  defp walk_results([value | values], bp_node, inner_type, res, [i | sub_path] = path, acc) do
    {result, res} = walk_result(value, bp_node, inner_type, res, path)
    walk_results(values, bp_node, inner_type, res, [i + 1 | sub_path], [result | acc])
  end

  defp walk_results([], _, _, res, _, acc), do: {:lists.reverse(acc), res}

  defp resolve_fields(parent, res, source, path) do
    # parent is the parent field, we need to get the return type of that field
    # that return type could be an interface or union, so let's make it concrete
    parent
    |> get_return_type
    |> get_concrete_type(source, res, path)
    |> case do
      nil ->
        {[], res}

      parent_type ->
        {fields, fields_cache} =
          Absinthe.Resolution.Projector.project(
            parent.selections,
            parent_type,
            path,
            res.fields_cache,
            res
          )

        res = %{res | fields_cache: fields_cache}

        {values, res} = do_resolve_fields(fields, res, source, parent_type, path, [])
        {values, %{res | path: path}}
    end
  end

  defp get_return_type(%{schema_node: %Type.Field{type: type}}) do
    Type.unwrap(type)
  end

  defp get_return_type(%{schema_node: schema_node}) do
    Type.unwrap(schema_node)
  end

  defp get_return_type(type), do: type

  defp get_concrete_type(%Type.Union{} = parent_type, source, res, path) do
    Type.Union.resolve_type(parent_type, source, %{res | path: path})
  end

  defp get_concrete_type(%Type.Interface{} = parent_type, source, res, path) do
    Type.Interface.resolve_type(parent_type, source, %{res | path: path})
  end

  defp get_concrete_type(parent_type, _source, _res, _path) do
    parent_type
  end

  defp do_resolve_fields([field | fields], res, source, parent_type, path, acc) do
    {result, res} = maybe_fast_resolve(field, res, source, parent_type, [field | path])
    do_resolve_fields(fields, res, source, parent_type, path, [result | acc])
  end

  defp do_resolve_fields([], res, _, _, _, acc), do: {:lists.reverse(acc), res}

  # Fast path for the default resolver. A field whose middleware is exactly
  # `[{MapGet, key}]` cannot error, suspend, or touch anything on the
  # resolution struct, so building one (and copying it again inside
  # `MapGet.call/2`) is pure overhead — we just fetch the value and build its
  # result directly. The fast path only applies when MapGet is the field's
  # *only* middleware; abstract return types fall through to the regular path
  # because `resolve_type` callbacks receive the resolution struct.
  #
  # NOTE: We plan to generalize this into an opt-in `{:fast, {module, fun,
  # args}}` middleware spec so that schemas which replace the default (e.g.
  # with an Ecto-aware getter) keep the fast path. That's a user-facing
  # feature with docs/validation/naming work attached — see
  # FAST_MIDDLEWARE_PLAN.md for the design and a validated prototype.
  defp maybe_fast_resolve(
         %{schema_node: %{middleware: [{Absinthe.Middleware.MapGet, key}]}} = field,
         res,
         source,
         parent_type,
         path
       ) do
    {emitter, res} = prepared_emitter(res, field, parent_type, path)
    full_type = emitter.schema_node.type

    case Type.unwrap(full_type) do
      %struct{} when struct in [Type.Union, Type.Interface] ->
        resolve_field(field, res, source, parent_type, path)

      _ ->
        value = Map.get(source, key)
        errors = maybe_add_non_null_error([], value, full_type)

        value
        |> to_result(emitter, full_type, res.extensions)
        |> add_errors(
          Enum.reverse(errors),
          &put_result_error_value(&1, &2, emitter, source, path)
        )
        |> walk_result(emitter, full_type, res, path)
        |> propagate_null_trimming
    end
  end

  defp maybe_fast_resolve(field, res, source, parent_type, path) do
    resolve_field(field, res, source, parent_type, path)
  end

  def resolve_field(field, res, source, parent_type, path) do
    res
    |> build_resolution_struct(field, source, parent_type, path)
    |> do_resolve_field(source, path)
  end

  # bp_field needs to have a concrete schema node, AKA no unions or interfaces
  defp do_resolve_field(res, source, path) do
    res
    |> reduce_resolution
    |> case do
      %{state: :resolved} = res ->
        build_result(res, source, path)

      %{state: :suspended} = res ->
        ref = make_ref()
        placeholder = %Result.Pending{ref: ref, emitter: res.definition}
        {placeholder, %{res | pending: [{ref, %{res | pending: []}} | res.pending]}}

      final_res ->
        raise """
        Should have halted or suspended middleware
        Started with: #{inspect(res)}
        Ended with: #{inspect(final_res)}
        """
    end
  end

  defp update_persisted_fields(dest, %{
         acc: acc,
         context: context,
         fields_cache: cache,
         pending: pending
       }) do
    %{dest | acc: acc, context: context, fields_cache: cache, pending: pending}
  end

  defp build_resolution_struct(
         res,
         %{argument_data: args, schema_node: %{middleware: middleware}} = bp_field,
         source,
         parent_type,
         path
       ) do
    %{
      res
      | path: path,
        state: :unresolved,
        value: nil,
        errors: [],
        source: source,
        parent_type: parent_type,
        middleware: middleware,
        definition: bp_field,
        arguments: args
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

  defp build_result(res, source, path) do
    %{
      value: value,
      extensions: extensions,
      errors: errors
    } = res

    # Every element of a list ends up with the same emitter (the field node
    # with its type expanded), so we build it once per field and reuse it
    # instead of rebuilding it for each element. It's never written back to
    # res.definition, so middleware sees no difference; result nodes carry the
    # same emitter values as before, just shared.
    {bp_field, res} = prepared_emitter(res, res.definition, res.parent_type, res.path)
    full_type = bp_field.schema_node.type

    # if there are any errors, the value is always nil
    value =
      case errors do
        [] -> value
        _ -> nil
      end

    errors = maybe_add_non_null_error(errors, value, full_type)

    value
    |> to_result(bp_field, full_type, extensions)
    |> add_errors(Enum.reverse(errors), &put_result_error_value(&1, &2, bp_field, source, path))
    |> walk_result(bp_field, full_type, res, path)
    |> propagate_null_trimming
  end

  defp prepared_emitter(%{fields_cache: cache} = res, bp_field, parent_type, path) do
    key = {:emitter, Absinthe.Resolution.Projector.cache_key(path, parent_type.identifier)}

    case Map.fetch(cache, key) do
      {:ok, emitter} ->
        {emitter, res}

      :error ->
        full_type = Type.expand(bp_field.schema_node.type, res.schema)
        emitter = put_in(bp_field.schema_node.type, full_type)
        {emitter, %{res | fields_cache: Map.put(cache, key, emitter)}}
    end
  end

  defp maybe_add_non_null_error(errors, value, type, path \\ [])

  defp maybe_add_non_null_error([], nil, %Type.NonNull{}, []) do
    ["Cannot return null for non-nullable field"]
  end

  defp maybe_add_non_null_error([], nil, %Type.NonNull{}, path) do
    [%{message: "Cannot return null for non-nullable field", path: Enum.reverse(path)}]
  end

  defp maybe_add_non_null_error([], value, %Type.NonNull{of_type: %Type.List{} = type}, path) do
    maybe_add_non_null_error([], value, type, path)
  end

  defp maybe_add_non_null_error([], [_ | _] = values, %Type.List{of_type: type}, path) do
    # Only a non-null element type can produce a violation, so plain `[Foo]`
    # lists skip the walk entirely. The element index is carried through the
    # recursion for the error path.
    if contains_non_null?(type) do
      list_non_null_errors(values, type, path, 0)
    else
      []
    end
  end

  defp maybe_add_non_null_error(errors, _, _, _path) do
    errors
  end

  defp list_non_null_errors([], _type, _path, _index), do: []

  defp list_non_null_errors([value | values], type, path, index) do
    case maybe_add_non_null_error([], value, type, [index | path]) do
      [] -> list_non_null_errors(values, type, path, index + 1)
      errors -> errors ++ list_non_null_errors(values, type, path, index + 1)
    end
  end

  defp contains_non_null?(%Type.NonNull{}), do: true
  defp contains_non_null?(%Type.List{of_type: inner}), do: contains_non_null?(inner)
  defp contains_non_null?(_), do: false

  defp propagate_null_trimming({%Result.List{values: values} = node, res}) do
    # Only rebuild the list when something actually needs to be trimmed; in the
    # common all-good case this avoids re-allocating the values list (and a
    # copy of the node) just to put back identical elements.
    if Enum.any?(values, &needs_trimming?/1) do
      values = Enum.map(values, &do_propagate_null_trimming/1)
      node = %{node | values: values}
      {do_propagate_null_trimming(node), res}
    else
      {node, res}
    end
  end

  defp propagate_null_trimming({node, res}) do
    {do_propagate_null_trimming(node), res}
  end

  defp do_propagate_null_trimming(node) do
    if bad_child = find_bad_child(node) do
      bp_field = node.emitter

      full_type =
        with %{type: type} <- bp_field.schema_node do
          type
        end

      nil
      |> to_result(bp_field, full_type, node.extensions)
      |> Map.put(:errors, node.errors ++ bad_child.errors)
    else
      node
    end
  end

  # A list element needs the trimming pass if it must be nulled out itself
  # (a bad child of its own) or if it violates the list's element nullability.
  defp needs_trimming?(element) do
    find_bad_child(element) || non_null_list_violation?(element)
  end

  defp find_bad_child(%Result.Object{fields: fields}) do
    Enum.find(fields, &non_null_violation?/1)
  end

  defp find_bad_child(%Result.List{values: values}) do
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

  defp non_null_list_violation?(%Result.List{values: values}) do
    Enum.find(values, &non_null_list_violation?/1)
  end

  # FIXME: Not super happy with this lookup process.
  # Also it would be nice if we could use the same function as above.
  defp non_null_list_violation?(%{value: nil, emitter: %{schema_node: %{type: type}}}) do
    !null_allowed_in_list?(type)
  end

  defp non_null_list_violation?(_) do
    false
  end

  defp null_allowed_in_list?(%Type.List{of_type: wrapped_type}) do
    null_allowed_in_list?(wrapped_type)
  end

  defp null_allowed_in_list?(%Type.NonNull{of_type: %Type.List{of_type: wrapped_type}}) do
    null_allowed_in_list?(wrapped_type)
  end

  defp null_allowed_in_list?(%Type.NonNull{of_type: _wrapped_type}) do
    false
  end

  defp null_allowed_in_list?(_type) do
    true
  end

  defp add_errors(result, errors, fun) do
    Enum.reduce(errors, result, fun)
  end

  defp put_result_error_value(error_value, result, bp_field, source, path) do
    case split_error_value(error_value) do
      {[], _} ->
        raise Absinthe.Resolution.result_error(error_value, bp_field, source)

      {[message: message, path: error_path], extra} ->
        put_error(
          result,
          error(bp_field, message, Enum.reverse(error_path) ++ path, Map.new(extra))
        )

      {[message: message], extra} ->
        put_error(result, error(bp_field, message, path, Map.new(extra)))
    end
  end

  defp split_error_value(error_value)
       when is_list(error_value) or (is_map(error_value) and not is_struct(error_value)) do
    Keyword.split(Enum.to_list(error_value), [:message, :path])
  end

  defp split_error_value(error_value) when is_binary(error_value) do
    {[message: error_value], []}
  end

  defp split_error_value(error_value) do
    {[message: to_string(error_value)], []}
  end

  defp to_result(nil, blueprint, _, extensions) do
    %Result.Leaf{emitter: blueprint, value: nil, extensions: extensions}
  end

  defp to_result(root_value, blueprint, %Type.NonNull{of_type: inner_type}, extensions) do
    to_result(root_value, blueprint, inner_type, extensions)
  end

  defp to_result(root_value, blueprint, %Type.Object{}, extensions) do
    %Result.Object{root_value: root_value, emitter: blueprint, extensions: extensions}
  end

  defp to_result(root_value, blueprint, %Type.Interface{}, extensions) do
    %Result.Object{root_value: root_value, emitter: blueprint, extensions: extensions}
  end

  defp to_result(root_value, blueprint, %Type.Union{}, extensions) do
    %Result.Object{root_value: root_value, emitter: blueprint, extensions: extensions}
  end

  # A list of nullable leaf values is kept as one compact node — see
  # Result.LeafList. Non-null element types don't match this clause and fall
  # through to the per-element form below, preserving null propagation.
  defp to_result(root_value, blueprint, %Type.List{of_type: %leaf{}}, extensions)
       when leaf in [Type.Scalar, Type.Enum] do
    %Result.LeafList{values: List.wrap(root_value), emitter: blueprint, extensions: extensions}
  end

  defp to_result(root_value, blueprint, %Type.List{of_type: inner_type}, extensions) do
    values =
      root_value
      |> List.wrap()
      |> Enum.map(&to_result(&1, blueprint, inner_type, extensions))

    %Result.List{values: values, emitter: blueprint, extensions: extensions}
  end

  defp to_result(root_value, blueprint, %Type.Scalar{}, extensions) do
    %Result.Leaf{
      emitter: blueprint,
      value: root_value,
      extensions: extensions
    }
  end

  defp to_result(root_value, blueprint, %Type.Enum{}, extensions) do
    %Result.Leaf{
      emitter: blueprint,
      value: root_value,
      extensions: extensions
    }
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
end
