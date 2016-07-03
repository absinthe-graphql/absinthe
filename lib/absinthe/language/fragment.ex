defmodule Absinthe.Language.Fragment do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    type_condition: nil,
    directives: [],
    selection_set: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: String.t,
    type_condition: nil | Language.NamedType.t,
    directives: [Language.Directive.t],
    selection_set: Language.SelectionSet.t,
    loc: Language.loc_t
  }

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.directives,
       List.wrap(node.selection_set)]
      |> Enum.concat
    end
  end
end
