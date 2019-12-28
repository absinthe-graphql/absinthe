defmodule Absinthe.Language.FragmentSpread do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            directives: [],
            loc: %{line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          directives: [Language.Directive.t()]
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Document.Fragment.Spread{
        name: node.name,
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
