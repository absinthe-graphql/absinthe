defmodule Absinthe.Language.InterfaceTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            description: nil,
            fields: [],
            directives: [],
            interfaces: [],
            loc: %{line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          fields: [Language.FieldDefinition.t()],
          directives: [Language.Directive.t()],
          interfaces: [Language.NamedType.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.InterfaceTypeDefinition{
        name: node.name,
        description: node.description,
        identifier: Macro.underscore(node.name) |> String.to_atom(),
        fields: Absinthe.Blueprint.Draft.convert(node.fields, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc),
        interfaces: interfaces(node.interfaces, doc),
        interface_blueprints: Absinthe.Blueprint.Draft.convert(node.interfaces, doc),
        source_location: source_location(node)
      }
    end

    defp interfaces(interfaces, doc) do
      interfaces
      |> Absinthe.Blueprint.Draft.convert(doc)
      |> Enum.map(&(&1.name |> Macro.underscore() |> String.to_atom()))
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.SourceLocation.at(loc)
  end
end
