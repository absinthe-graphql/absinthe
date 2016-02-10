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
    {result, execution_to_return} = selections
    |> Enum.reduce(%{}, fn
      selection, acc ->
        case flatten(selection, execution) do
          %{} = result ->
            Map.merge(acc, %{parent_type => result}, fn
              _, val1, val2 ->
                Map.merge(val1, val2)
            end)
          {concrete_parent_type, result} ->
            Map.merge(acc, %{concrete_parent_type => result}, fn
              _, val1, val2 ->
                Map.merge(val1, val2)
            end)
        end
    end)
    |> Enum.reduce({%{}, execution}, fn ({field_parent_type, fields}, type_acc) ->
      Enum.reduce(fields, type_acc, fn
        {name, ast_node}, {acc, exe}  ->
          field_resolution = %Resolution{parent_type: field_parent_type, target: target}
          case resolve_field(ast_node, %{exe | resolution: field_resolution}) do
            {:ok, value, changed_execution} ->
              {acc |> Map.put(name, value), changed_execution}
            {:skip, changed_execution} ->
              {acc, changed_execution}
          end
      end)
    end)
    {:ok, result, execution_to_return}
  end

  @spec flatten(Language.t, Execution.t) :: %{binary => Language.t}
  defp flatten(%Language.Field{alias: alias, name: name} = ast_node, _execution) do
    alias_or_name = alias || name
    %{alias_or_name => ast_node}
  end

  defp flatten(%Language.FragmentSpread{} = ast_node, execution) do
    case Absinthe.Execution.Directives.check(execution, ast_node) do
      {:skip, _} ->
        %{}
      {flag, exe} when flag in [:ok, :include] ->
        exe.fragments[ast_node.name]
        |> flatten_fragment(execution)
    end
  end
  defp flatten(%Language.InlineFragment{} = ast_node, execution) do
    case Absinthe.Execution.Directives.check(execution, ast_node) do
      {:skip, _} ->
        %{}
      {flag, _exe} when flag in [:ok, :include] ->
        flatten_fragment(ast_node, execution)
    end
  end

  # For missing fragments
  defp flatten(nil = _ast_node, _execution) do
    %{}
  end

  defp flatten_fragment(fragment, execution) do
    case type_for_fragment(fragment, execution) do
      nil ->
        %{}
      type ->
        {type, do_flatten_fragment(fragment, execution)}
    end
  end
  defp do_flatten_fragment(fragment, execution) do
    fragment.selection_set.selections
    |> Enum.reduce(%{}, fn (selection, acc) ->
      flatten(selection, execution)
      |> Enum.reduce(acc, fn ({_name, selection}, acc_for_selection) ->
        merge_into_result(acc_for_selection, selection, execution)
      end)
    end)
  end

  @spec type_for_fragment(Language.FragmentSpread.t | Language.InlineFragment.t, Execution.t) :: Type.t | nil
  defp type_for_fragment(%{type_condition: type_condition}, %{resolution: %{type: type, target: target}, schema: schema} = execution) do
    this_type = Schema.lookup_type(schema, type)
    condition_type = if type_condition, do: Schema.lookup_type(schema, type_condition.name)
    case this_type do
      %{__struct__: type_name} when type_name in [Type.Union, Type.Interface] ->
        resolved = Execution.concrete_type(this_type, target, execution)
        if condition_type do
          if Type.equal?(resolved, condition_type), do: resolved
        else
          resolved
        end
      _ ->
        if condition_type do
          if Type.equal?(this_type, condition_type), do: this_type
        else
          this_type
        end
    end
  end

  @spec merge_into_result(map, Language.t, Execution.t) :: map
  defp merge_into_result(acc, %{alias: alias} = selection, execution) when not is_nil(alias) do
    acc
    |> do_merge_into_result(%{alias => selection}, execution)
  end
  defp merge_into_result(acc, %{name: name} = selection, execution) do
    acc
    |> do_merge_into_result(%{name => selection}, execution)
  end

  defp do_merge_into_result(acc, change, execution) do
    acc
    |> Map.merge(change, fn (_name, field1, field2) ->
      merge_fields(field1, field2, execution)
    end)
  end

  @spec merge_fields(Language.t, Language.t, Execution.t) :: Language.t
  defp merge_fields(_field1, field2, %{schema: _schema}) do
    # TODO: Merge fields into a new Language.Field.t if the field_type is Object.t
    # field_type = schema |> Schema.field(resolution.type, field2.name).type |> Type.unwrap
    field2
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
