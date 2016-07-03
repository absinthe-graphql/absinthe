defmodule Absinthe.Language.FragmentSpread do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    directives: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: String.t,
    directives: [Language.Directive.t]
  }

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      node.directives
    end
  end

end
