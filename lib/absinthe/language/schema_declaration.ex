defmodule Absinthe.Language.SchemaDeclaration do
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
      %Blueprint.Schema.SchemaDeclaration{
        description: node.description,
        field_definitions: Absinthe.Blueprint.Draft.convert(node.fields, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc),
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.SourceLocation.at(loc)
  end
end
