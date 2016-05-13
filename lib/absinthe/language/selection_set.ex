defmodule Absinthe.Language.SelectionSet do

  @moduledoc false

  defstruct selections: [], loc: %{start_line: nil}

  defimpl Absinthe.Traversal.Node do

    def children(node, _schema), do: node.selections

  end

end
