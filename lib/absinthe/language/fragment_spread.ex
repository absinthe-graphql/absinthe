defmodule Absinthe.Language.FragmentSpread do

  @moduledoc false

  @type t :: %{name: binary, directives: [Absinthe.Language.Directive.t]}
  defstruct name: nil, directives: [], loc: %{start_line: nil}

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      node.directives
    end
  end

end
