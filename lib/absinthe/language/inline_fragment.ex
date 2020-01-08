defmodule Absinthe.Language.InlineFragment do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct type_condition: nil,
            directives: [],
            selection_set: nil,
            loc: %{line: nil}

  @type t :: %__MODULE__{
          type_condition: nil | Language.NamedType.t(),
          directives: [Language.Directive.t()],
          selection_set: Language.SelectionSet.t(),
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Document.Fragment.Inline{
        type_condition: Blueprint.Draft.convert(node.type_condition, doc),
        selections: Blueprint.Draft.convert(node.selection_set.selections, doc),
        directives: Blueprint.Draft.convert(node.directives, doc),
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}) do
      nil
    end

    defp source_location(%{loc: loc}) do
      Blueprint.SourceLocation.at(loc)
    end
  end
end
