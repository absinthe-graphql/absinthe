defmodule Absinthe.Language.SchemaDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct directives: [],
            fields: [],
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          directives: [Language.Directive.t()],
          fields: [Language.FieldDefinition.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.SchemaDefinition{
        fields: Absinthe.Blueprint.Draft.convert(node.fields, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc)
      }
    end
  end
end
