defmodule Absinthe.Language.ScalarTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            directives: [],
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          directives: [Language.Directive.t()],
          loc: Language.t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.ScalarTypeDefinition{
        name: node.name,
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc)
      }
    end
  end
end
