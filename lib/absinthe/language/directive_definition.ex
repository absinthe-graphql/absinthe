defmodule Absinthe.Language.DirectiveDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            description: nil,
            arguments: [],
            directives: [],
            locations: [],
            loc: %{line: nil},
            repeatable: false

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          directives: [Language.Directive.t()],
          arguments: [Language.Argument.t()],
          locations: [String.t()],
          loc: Language.loc_t(),
          repeatable: boolean()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.DirectiveDefinition{
        name: node.name,
        identifier: Macro.underscore(node.name) |> String.to_atom(),
        description: node.description,
        arguments: Absinthe.Blueprint.Draft.convert(node.arguments, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc),
        locations: node.locations,
        repeatable: node.repeatable,
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.SourceLocation.at(loc)
  end
end
