defmodule Absinthe.Language.ObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            directives: [],
            interfaces: [],
            fields: [],
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          directives: [Language.Directive.t()],
          interfaces: [Language.NamedType.t()],
          fields: [Language.FieldDefinition.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.ObjectTypeDefinition{
        name: node.name,
        fields: Absinthe.Blueprint.Draft.convert(node.fields, doc),
        interfaces: Absinthe.Blueprint.Draft.convert(node.interfaces, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc)
      }
    end
  end
end
