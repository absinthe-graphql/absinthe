defmodule Absinthe.Language.FieldDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            description: nil,
            arguments: [],
            directives: [],
            type: nil,
            complexity: nil,
            loc: %{line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          arguments: [Language.Argument.t()],
          directives: [Language.Directive.t()],
          type: Language.type_reference_t(),
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.FieldDefinition{
        name: node.name |> Macro.underscore(),
        description: node.description,
        identifier: node.name |> Macro.underscore() |> String.to_atom(),
        arguments: Absinthe.Blueprint.Draft.convert(node.arguments, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc),
        type: Absinthe.Blueprint.Draft.convert(node.type, doc),
        complexity: node.complexity,
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.SourceLocation.at(loc)
  end
end
