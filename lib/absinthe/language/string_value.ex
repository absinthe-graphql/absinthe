defmodule Absinthe.Language.StringValue do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct [
    value: nil,
    loc: %{}
  ]

  @type t :: %__MODULE__{
    value: String.t,
    loc: Language.loc_t
  }

  defimpl Blueprint.Draft do
    def convert(node, _doc) do
      %Blueprint.Input.String{
        value: node.value,
      }
    end
  end

end
