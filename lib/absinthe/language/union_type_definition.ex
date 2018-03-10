defmodule Absinthe.Language.UnionTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            directives: [],
            types: [],
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          directives: [Language.Directive.t()],
          types: [Language.NamedType.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.UnionTypeDefinition{
        name: node.name,
        types: Absinthe.Blueprint.Draft.convert(node.types, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc)
      }
    end
  end
end
