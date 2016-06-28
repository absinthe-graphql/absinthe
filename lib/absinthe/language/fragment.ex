defmodule Absinthe.Language.Fragment do

  @moduledoc false

  defstruct name: nil, type_condition: nil, directives: [], selection_set: nil, loc: %{start_line: nil}

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.directives,
       List.wrap(node.selection_set)]
      |> Enum.concat
    end
  end
end
