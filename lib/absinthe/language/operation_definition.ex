defmodule Absinthe.Language.OperationDefinition do

  @moduledoc false

  defstruct operation: nil, name: nil, variable_definitions: [], directives: [], selection_set: nil, loc: %{start_line: nil}

  defimpl Absinthe.Traversal.Node do

    def children(node, _schema) do
      [node.variable_definitions,
       node.directives,
       List.wrap(node.selection_set)]
      |> Enum.concat
    end

  end

end
