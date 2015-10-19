defmodule ExGraphQL.Language.SelectionSet do
  defstruct selections: [], loc: %{start: nil}

  defimpl ExGraphQL.Language.Node do

    def children(node), do: node.selections

  end

end
