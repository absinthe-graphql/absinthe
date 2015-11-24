defmodule ExGraphQL.Language.SelectionSet do
  defstruct selections: [], loc: %{start: nil}

  defimpl ExGraphQL.Language.Node do

    def children(node), do: node.selections

  end

  defimpl ExGraphQL.Execution.Resolution do

    def resolve(%{selections: selections}, target, %{strategy: :serial} = execution) do
      selections
      |> flatten
      |> Enum.reduce(%{}, fn (ast_node, acc) ->
        acc
        |> Map.merge(
          ExGraphQL.Execution.Resolution.resolve(
            ast_node,
            target,
            execution
          )
        )
      end)
    end

    # See https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/query/serial_execution/selection_resolution.rb
    defp flatten(selections) do
      [] # STUB
    end

  end

end
