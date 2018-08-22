defmodule Absinthe.Language.ScalarTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            description: nil,
            directives: [],
            loc: %{line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          directives: [Language.Directive.t()],
          loc: Language.t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.ScalarTypeDefinition{
        name: node.name,
        description: node.description,
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc)
      }
    end
  end
end
