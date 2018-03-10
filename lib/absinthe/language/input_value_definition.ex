defmodule Absinthe.Language.InputValueDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    default_value: nil,
    directives: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          type: Language.input_t(),
          default_value: Language.input_t(),
          directives: [Language.Directive.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.InputValueDefinition{
        name: node.name,
        type: Blueprint.Draft.convert(node.type, doc),
        default_value: Blueprint.Draft.convert(node.default_value, doc),
        directives: Blueprint.Draft.convert(node.directives, doc)
      }
    end
  end
end
