defmodule Absinthe.Language.IntValue do
  @moduledoc false

  alias Absinthe.Blueprint

  defstruct [
    value: nil,
  ]

  @type t :: %__MODULE__{
    value: integer,
  }

  defimpl Blueprint.Draft do
    def convert(node, _doc) do
      %Blueprint.Input.Integer{
        value: node.value,
      }
    end
  end

end
