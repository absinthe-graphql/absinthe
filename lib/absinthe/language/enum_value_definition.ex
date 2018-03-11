defmodule Absinthe.Language.EnumValueDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:value]
  defstruct [
    :value,
    directives: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
          value: String.t(),
          directives: [Language.Directive.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.EnumValueDefinition{
        value: node.value,
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc),
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)
  end
end
