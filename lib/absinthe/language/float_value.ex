defmodule Absinthe.Language.FloatValue do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct [
    value: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    value: float,
    loc: Language.loc_t
  }

  defimpl Blueprint.Draft do
    def convert(node, _doc) do
      %Blueprint.Input.Float{
        value: node.value,
      }
    end
  end

end
