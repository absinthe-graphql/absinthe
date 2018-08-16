defmodule Absinthe.Language.SchemaDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct description: nil,
            directives: [],
            fields: [],
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          description: nil | String.t(),
          directives: [Language.Directive.t()],
          fields: [Language.FieldDefinition.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.SchemaDefinition{
        description: node.description,
        types: Absinthe.Blueprint.Draft.convert(node.fields, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc)
      }
    end
  end
end
