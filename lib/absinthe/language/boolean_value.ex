defmodule Absinthe.Language.BooleanValue do
  @moduledoc false

  alias Absinthe.Blueprint

  defstruct [
    value: nil,
    loc: %{}
  ]

  @type t :: %__MODULE__{
    value: boolean,
    loc: Absinthe.Language.loc_t
  }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Input.Boolean{
        value: Absinthe.Blueprint.Draft.convert(node.value, doc)
      }
    end
  end

end
