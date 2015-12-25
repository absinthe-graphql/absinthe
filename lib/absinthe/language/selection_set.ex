defmodule Absinthe.Language.SelectionSet do
  defstruct selections: [], loc: %{start: nil}

  defimpl Absinthe.Traversal.Node do

    def children(node, _schema), do: node.selections

  end

end
