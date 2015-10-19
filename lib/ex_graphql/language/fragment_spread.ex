defmodule ExGraphQL.Language.FragmentSpread do

  @type t :: %{name: binary, directives: [ExGraphQL.Language.Directive.t]}
  defstruct name: nil, directives: [], loc: %{start: nil}

  defimpl ExGraphQL.Language.Node do
    def children(node) do
      node.directives
    end
  end

end
