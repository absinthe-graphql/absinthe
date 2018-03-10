defmodule Absinthe.Language.EnumTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil,
            values: [],
            directives: [],
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          name: String.t(),
          values: [String.t()],
          directives: [Language.Directive.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.EnumTypeDefinition{
        name: node.name,
        values: Absinthe.Blueprint.Draft.convert(node.values, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc)
      }
    end
  end
end
