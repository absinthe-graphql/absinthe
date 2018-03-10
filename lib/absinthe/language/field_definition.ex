defmodule Absinthe.Language.FieldDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            arguments: [],
            directives: [],
            type: nil,
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          arguments: [Language.Argument.t()],
          directives: [Language.Directive.t()],
          type: Language.type_reference_t(),
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.FieldDefinition{
        name: node.name,
        arguments: Absinthe.Blueprint.Draft.convert(node.arguments, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc),
        type: Absinthe.Blueprint.Draft.convert(node.type, doc)
      }
    end
  end
end
