defmodule Absinthe.Language.DirectiveDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            arguments: [],
            directives: [],
            locations: [],
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          directives: [Language.Directive.t()],
          arguments: [Language.Argument.t()],
          locations: [String.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.DirectiveDefinition{
        name: node.name,
        arguments: Absinthe.Blueprint.Draft.convert(node.arguments, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc),
        locations: node.locations
      }
    end
  end
end
