defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Language.SelectionSet do

  alias ExGraphQL.Execution
  alias ExGraphQL.Execution.Resolution
  alias ExGraphQL.Language
  alias ExGraphQL.Type

  @spec resolve(Language.SelectionSet.t,
                Resolution.t,
                Execution.t) :: {:ok, map} | {:error, any}
  def resolve(%{selections: selections}, resolution, %{strategy: :serial} = execution) do
    {result, execution_to_return} = selections
    |> Enum.map(&(flatten(&1, resolution, execution)))
    |> Enum.reduce(&Map.merge/2)
    |> Enum.reduce({%{}, execution}, fn ({name, ast_node}, {acc, exe}) ->
      case resolve_field(
            ast_node,
            %Resolution{
              parent_type: resolution.type,
              target: resolution.target
            },
            exe
          ) do
        {:ok, value, changed_execution} -> {acc |> Map.put(name, value), changed_execution}
        {:skip, changed_execution} -> {acc, changed_execution}
      end
    end)
    {:ok, result, execution_to_return}
  end

  @spec flatten(Language.t, Resolution.t, Execution.t) :: %{binary => Language.t}
  defp flatten(%{__struct__: Language.Field, alias: alias, name: name} = ast_node, _target, _execution) do
    alias_or_name = alias || name
    %{alias_or_name => ast_node}
  end
  defp flatten(%{__struct__: Language.InlineFragment} = ast_node, resolution, execution) do
    if directives_pass?(ast_node, execution) && can_apply_fragment?(ast_node, resolution, execution) do
      ast_node.selection_set.selections
      |> Enum.reduce(%{}, fn (selection, acc) ->
        flatten(selection, resolution, execution)
        |> Enum.reduce(acc, fn ({_name, selection}, acc_for_selection) ->
          merge_into_result(acc_for_selection, selection, resolution, execution)
        end)
      end)
    else
      %{}
    end
  end
  defp flatten(%{__struct__: Language.FragmentSpread, name: name} = ast_node, resolution, %{fragments: fragments} = execution) do
    if directives_pass?(ast_node, execution) do
      flatten(fragments[name], resolution, execution)
    else
      %{}
    end
  end
  # For missing fragments
  defp flatten(nil = _ast_node, _resolution, _execution) do
    %{}
  end

  defp can_apply_fragment?(%{type_condition: type_condition}, resolution, %{schema: schema}) do
    child_type = schema.type_map[type_condition]
    Execution.resolve_type(nil, child_type, resolution.type)
  end

  @spec merge_into_result(map, Language.t, Resolution.t, Execution.t) :: map
  defp merge_into_result(acc, %{alias: alias} = selection, resolution, execution) do
    acc
    |> do_merge_into_result(%{alias => selection}, resolution, execution)
  end
  defp merge_into_result(acc, %{name: name} = selection, resolution, execution) do
    acc
    |> do_merge_into_result(%{name => selection}, resolution, execution)
  end

  defp do_merge_into_result(acc, change, resolution, execution) do
    acc
    |> Map.merge(change, fn (_name, field1, field2) ->
      merge_fields(field1, field2, resolution, execution)
    end)
  end

  @spec merge_fields(Language.t, Language.t, Resolution.t, Execution.t) :: Language.t
  defp merge_fields(_field1, field2, _resolution, %{schema: _schema}) do
    # TODO: Merge fields into a new Language.Field.t if the field_type is ObjectType.t
    # field_type = schema |> Schema.field(resolution.type, field2.name).type |> Type.unwrap
    field2
  end

  defp resolve_field(ast_node, resolution, execution) do
    if directives_pass?(ast_node, execution) do
      Execution.Resolution.resolve(ast_node, resolution, execution)
    else
      {:skip, execution}
    end
  end

  # TODO: Actually check directives
  defp directives_pass?(_ast_node, _execution) do
    true
  end

end
