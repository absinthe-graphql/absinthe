defmodule Absinthe.Language.SelectionSet do
  defstruct selections: [], loc: %{start: nil}

  defimpl Absinthe.Language.Node do

    def children(node), do: node.selections

  end

end
