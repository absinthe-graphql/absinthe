defmodule Absinthe.Language.InputObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            description: nil,
            fields: [],
            directives: [],
            loc: %{line: nil},
            errors: []

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          fields: [Language.InputValueDefinition.t()],
          directives: [Language.Directive.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.InputObjectTypeDefinition{
        name: node.name,
        description: node.description,
        fields:
          for value <- Absinthe.Blueprint.Draft.convert(node.fields, doc) do
            %{value | placement: :input_field_definition}
          end,
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc)
      }
    end
  end
end
