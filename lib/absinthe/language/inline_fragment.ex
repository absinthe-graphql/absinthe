defmodule Absinthe.Language.InlineFragment do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    type_condition: nil,
    directives: [],
    selection_set: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    type_condition: nil | Language.NamedType.t,
    directives: [Language.Directive.t],
    selection_set: Language.SelectionSet.t,
    loc: Language.loc_t
  }

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [List.wrap(node.type_condition),
       node.directives,
       List.wrap(node.selection_set)]
      |> Enum.concat
    end
  end

end
