defmodule Absinthe.Language.ObjectField do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct [
    name: nil,
    value: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Language.value_t,
    loc: Language.loc_t
  }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Input.Field{
        name: node.name,
        value: Blueprint.Draft.convert(node.value, doc),
      }
    end
  end

end
