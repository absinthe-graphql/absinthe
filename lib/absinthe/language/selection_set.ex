defmodule Absinthe.Language.SelectionSet do
  @moduledoc false

  alias Absinthe.Language

  defstruct selections: [],
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          selections: [
            Language.FragmentSpread.t() | Language.InlineFragment.t() | Language.Field.t()
          ],
          loc: Language.loc_t()
        }

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      node.selections
    end
  end
end
