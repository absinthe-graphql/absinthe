defmodule Absinthe.Language.InputValueDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    default_value: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: String.t,
    type: Language.input_t,
    default_value: Blueprint.Input.t,
    loc: Language.loc_t,
  }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.IDL.InputValueDefinition{
        name: node.name,
        type: Blueprint.Draft.convert(node.type, doc),
        default_value: Blueprint.Draft.convert(node.default_value, doc),
      }
    end
  end

end
