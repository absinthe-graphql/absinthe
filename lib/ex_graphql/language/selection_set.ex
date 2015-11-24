defmodule ExGraphQL.Language.SelectionSet do
  defstruct selections: [], loc: %{start: nil}

  defimpl ExGraphQL.Language.Node do

    def children(node), do: node.selections

  end

  defimpl ExGraphQL.Execution.Resolution do

    alias ExGraphQL.Execution
    alias ExGraphQL.Language
    alias ExGraphQL.Type

    @spec resolve(ExGraphQL.Language.SelectionSet.t,
                  ExGraphQL.Type.t,
                  ExGraphQL.Execution.t) :: {:ok, map} | {:error, any}
    def resolve(%{selections: selections}, type, %{strategy: :serial} = execution) do
      selections
      |> Enum.map(&(flatten(&1, type, execution)))
      |> Enum.reduce(&Map.merge/2)
      |> Enum.reduce(%{}, fn ({name, ast_node}, acc) ->
        acc
        |> Map.put(
          name,
          Execution.Resolution.resolve(
            ast_node,
            type,
            execution
          )
        )
      end)
    end

    defp flatten(%{__struct__: Language.Field, alias: alias, name: name} = ast_node, _target, _execution) do
      alias_or_name = alias || name
      %{alias_or_name => ast_node}
    end
    defp flatten(%{__struct__: Language.InlineFragment} = ast_node, type, execution) do
      if directives_pass?(ast_node, execution) && can_apply_fragment?(ast_node, type, execution) do
        ast_node.selection_set.selections
        |> Enum.reduce(%{}, fn (selection, acc) ->
          flatten(selection, type, execution)
          |> Enum.reduce(acc, fn ({name, selection}, acc_for_selection) ->
            merge_into_result(acc_for_selection, selection, type, execution)
          end)
        end)
      else
        %{}
      end
    end
    defp flatten(%{__struct__: Language.FragmentSpread, name: name} = ast_node, type, %{fragments: fragments} = execution) do
      if directives_pass?(ast_node, execution) do
        flatten(fragments[name], type, execution)
      else
        %{}
      end
    end
    # For missing fragments
    defp flatten(nil = _ast_node, _type, _execution) do
      %{}
    end

    defp can_apply_fragment?(%{type_condition: type_condition}, type, %{schema: schema}) do
      child_type = schema.type_map[type_condition]
      Execution.resolve_type(nil, child_type, type)
    end

    @spec merge_into_result(map, Language.t, Type.t, Execution.t) :: map
    defp merge_into_result(acc, %{alias: alias} = selection, type, execution) do
      acc
      |> do_merge_into_result(%{alias => selection}, type, execution)
    end
    defp merge_into_result(acc, %{name: name} = selection, type, execution) do
      acc
      |> do_merge_into_result(%{name => selection}, type, execution)
    end

    defp do_merge_into_result(acc, change, type, execution) do
      acc
      |> Map.merge(change, fn (name, field1, field2) ->
        merge_fields(field1, field2, type, execution)
      end)
    end

    @spec merge_fields(Language.t, Language.t, Type.t, Execution.t) :: Language.t
    defp merge_fields(field1, field2, type, %{schema: schema}) do
      # TODO: Merge fields into a new Language.Field.t if the field_type is ObjectType.t
      # field_type = schema |> Schema.field(type, field2.name).type |> Type.unwrap
      field2
    end

    # TODO: Actually check directives
    def directives_pass?(_ast_node, _execution) do
      true
    end

  end

end
