defimpl Absinthe.Execution.Resolution, for: Absinthe.Language.SelectionSet do

  alias Absinthe.Execution
  alias Absinthe.Execution.Resolution
  alias Absinthe.Language
  alias Absinthe.Schema
  alias Absinthe.Type

  @spec resolve(Language.SelectionSet.t,
                Execution.t) :: {:ok, map} | {:error, any}
  def resolve(%{selections: selections}, %{resolution: %{type: type, target: target}, strategy: :serial} = execution) do
    parent_type = Schema.lookup_type(execution.schema, type)
    {flattened, exe} = flatten(selections, parent_type, execution)
    {result, execution_to_return} = Enum.reduce(squash(flattened), {%{}, exe}, fn
      {field_parent_type, {name, ast_node}}, {values, field_exe} ->
        field_resolution = %Resolution{parent_type: field_parent_type, target: target}
        case resolve_field(ast_node, %{field_exe | resolution: field_resolution}) do
          {:ok, value, changed_execution} ->
            {values |> Map.put(name, value), changed_execution}
          {:skip, changed_execution} ->
            {values, changed_execution}
        end
    end)
    {:ok, result, execution_to_return}
  end

  # Remove instructions with the same name, preferring
  # later ones
  defp squash(instructions) do
    instructions
    |> Enum.reverse
    |> Enum.uniq_by(fn
      {_type, {name, _ast_node}} ->
        name
    end)
    |> Enum.reverse
  end

  defp flatten(items, type, execution) when is_list(items) do
    Enum.flat_map_reduce(items, execution, &flatten(&1, type, &2))
  end
  defp flatten(%Language.Field{alias: alias, name: name} = ast_node, type, execution) do
    alias_or_name = alias || name
    {[{type, {alias_or_name, ast_node}}], execution}
  end
  defp flatten(%Language.FragmentSpread{} = ast_node, default_type, execution) do
    case Absinthe.Execution.Directives.check(execution, ast_node) do
      {:skip, exe} ->
        {[], exe}
      {flag, exe} when flag in [:ok, :include] ->
        type = type_for_fragment(ast_node, execution) || default_type
        flatten(exe.fragments[ast_node.name], type, execution)
    end
  end
  defp flatten(%{__struct__: str} = ast_node, parent_type, execution) when str in [Language.InlineFragment, Language.Fragment] do
    case Absinthe.Execution.Directives.check(execution, ast_node) do
      {:skip, _} ->
        {[], execution}
      {flag, _exe} when flag in [:ok, :include] ->
        fragment_type = type_for_fragment(ast_node, execution)
        if allow_fragment?(ast_node, fragment_type, parent_type) do
          flatten(ast_node.selection_set.selections, fragment_type, execution)
        else
          {[], execution}
        end
    end
  end
  # For missing fragments
  defp flatten(nil, _, execution) do
    {[], execution}
  end

  defp allow_fragment?(%{type_condition: nil}, _, _) do
    true
  end
  defp allow_fragment?(_, %{name: name}, %{name: name}) do
    true
  end
  defp allow_fragment?(_, fragment_type, %{__struct__: str} = object_type) when str in [Type.Interface, Type.Union] do
    str.member?(object_type, fragment_type)
  end
  defp allow_fragment?(_, _, _) do
    false
  end

  @spec type_for_fragment(Language.FragmentSpread.t | Language.InlineFragment.t, Execution.t) :: Type.t | nil
  defp type_for_fragment(%{type_condition: type_condition}, %{resolution: %{type: type, target: target}, schema: schema} = execution) do
    this_type = Schema.lookup_type(schema, type)
    condition_type = if type_condition, do: Schema.lookup_type(schema, type_condition.name)
    case this_type do
      %{__struct__: type_name} when type_name in [Type.Union, Type.Interface] ->
        resolved = Execution.concrete_type(this_type, target, execution)
        if condition_type do
          if Type.equal?(this_type, condition_type) || Type.equal?(resolved, condition_type) do
            resolved
          else
            nil
          end
        else
          resolved
        end
      _ ->
        case condition_type do
          %{__struct__: cond_str} when cond_str in [Type.Union, Type.Interface] ->
            if cond_str.member?(condition_type, this_type), do: this_type
          nil ->
            this_type
          _ ->
            if Type.equal?(this_type, condition_type), do: this_type
        end
    end
  end
  defp type_for_fragment(_, _) do
    nil
  end

  defp resolve_field(ast_node, execution) do
    case Absinthe.Execution.Directives.check(execution, ast_node) do
      {:skip, _} = skipping ->
        skipping
      {flag, exe} when flag in [:ok, :include] ->
        Execution.Resolution.resolve(ast_node, exe)
    end
  end

end
