defmodule ExGraphQL.Language.OperationDefinition do
  defstruct operation: nil, name: nil, variable_definitions: [], directives: [], selection_set: nil, loc: %{start: nil}

  defimpl ExGraphQL.Language.Node do

    def children(node) do
      [node.variable_definitions,
       node.directives,
       List.wrap(node.selection_set)]
      |> Enum.concat
    end

  end

  defimpl ExGraphQL.Execution.Resolution do

    def resolve(operation, target, execution) do
      ExGraphQL.Execution.Resolution.resolve(
        operation.selection_set,
        target,
        execution
      )
    end

  end

end
