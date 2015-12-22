defmodule Absinthe.Language.FragmentSpread do

  @type t :: %{name: binary, directives: [Absinthe.Language.Directive.t]}
  defstruct name: nil, directives: [], loc: %{start: nil}

  defimpl Absinthe.Language.Node do
    def children(node) do
      node.directives
    end
  end

end
