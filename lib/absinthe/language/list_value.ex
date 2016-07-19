defmodule Absinthe.Language.ListValue do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct [
    values: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    values: [Language.value_t],
    loc: Language.loc_t
  }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Input.List{
        values: Blueprint.Draft.convert(node.values, doc)
      }
    end
  end

end
