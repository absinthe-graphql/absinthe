defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Language.SelectionSet do

  alias ExGraphQL.Execution
  alias ExGraphQL.Execution.Resolution
  alias ExGraphQL.Language

  @spec resolve(Language.SelectionSet.t,
                Execution.t) :: {:ok, map} | {:error, any}
  def resolve(%{selections: selections}, %{resolution: %{type: type, target: target}, strategy: :serial} = execution) do
    {result, execution_to_return} = selections
    |> Enum.map(&(flatten(&1, execution)))
    |> Enum.reduce(&Map.merge/2)
    |> Enum.reduce({%{}, execution}, fn ({name, ast_node}, {acc, exe}) ->
      field_resolution = %Resolution{parent_type: type, target: target}
      case resolve_field(ast_node, %{exe | resolution: field_resolution}) do
        {:ok, value, changed_execution} -> {acc |> Map.put(name, value), changed_execution}
        {:skip, changed_execution} -> {acc, changed_execution}
      end
    end)
    {:ok, result, execution_to_return}
  end

  @spec flatten(Language.t, Execution.t) :: %{binary => Language.t}
  defp flatten(%Language.Field{alias: alias, name: name} = ast_node, _execution) do
    alias_or_name = alias || name
    %{alias_or_name => ast_node}
  end
  defp flatten(%Language.InlineFragment{} = ast_node, execution) do
    if directives_pass?(ast_node, execution) && can_apply_fragment?(ast_node, execution) do
      ast_node.selection_set.selections
      |> Enum.reduce(%{}, fn (selection, acc) ->
        flatten(selection, execution)
        |> Enum.reduce(acc, fn ({_name, selection}, acc_for_selection) ->
          merge_into_result(acc_for_selection, selection, execution)
        end)
      end)
    else
      %{}
    end
  end
  defp flatten(%Language.FragmentSpread{name: name} = ast_node, %{fragments: fragments} = execution) do
    if directives_pass?(ast_node, execution) do
      flatten(fragments[name], execution)
    else
      %{}
    end
  end
  # For missing fragments
  defp flatten(nil = _ast_node, _execution) do
    %{}
  end

  defp can_apply_fragment?(%{type_condition: type_condition}, %{resolution: %{type: type}, schema: schema}) do
    child_type = schema.type_map[type_condition]
    Execution.resolve_type(nil, child_type, type)
  end

  @spec merge_into_result(map, Language.t, Execution.t) :: map
  defp merge_into_result(acc, %{alias: alias} = selection, execution) do
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
    # TODO: Merge fields into a new Language.Field.t if the field_type is ObjectType.t
    # field_type = schema |> Schema.field(resolution.type, field2.name).type |> Type.unwrap
    field2
  end

  defp resolve_field(ast_node, execution) do
    if directives_pass?(ast_node, execution) do
      Execution.Resolution.resolve(ast_node, execution)
    else
      {:skip, execution}
    end
  end

  # TODO: Actually check directives
  defp directives_pass?(_ast_node, _execution) do
    true
  end

end
