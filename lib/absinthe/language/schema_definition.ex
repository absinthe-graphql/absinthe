defmodule Absinthe.Language.SchemaDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct description: nil,
            directives: [],
            fields: [],
            loc: %{line: nil}

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
        type_definitions: Absinthe.Blueprint.Draft.convert(node.fields, doc),
        directive_definitions: Absinthe.Blueprint.Draft.convert(node.directives, doc)
      }
    end
  end
end
