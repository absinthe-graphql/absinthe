defmodule Absinthe.Language.FragmentSpread do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            directives: [],
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          directives: [Language.Directive.t()]
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Document.Fragment.Spread{
        name: node.name,
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
      node.directives
    end
  end
end
