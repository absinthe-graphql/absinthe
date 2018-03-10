defmodule Absinthe.Language.Fragment do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            type_condition: nil,
            directives: [],
            selection_set: nil,
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          type_condition: nil | Language.NamedType.t(),
          directives: [Language.Directive.t()],
          selection_set: Language.SelectionSet.t(),
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Document.Fragment.Named{
        name: node.name,
        type_condition: Blueprint.Draft.convert(node.type_condition, doc),
        selections: Blueprint.Draft.convert(node.selection_set.selections, doc),
        directives: Blueprint.Draft.convert(node.directives, doc),
        source_location: source_location(node.loc)
      }
    end

    defp source_location(nil) do
      nil
    end

    defp source_location(%{start_line: number}) do
      Blueprint.Document.SourceLocation.at(number)
    end
  end

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.directives, List.wrap(node.selection_set)]
      |> Enum.concat()
    end
  end
end
