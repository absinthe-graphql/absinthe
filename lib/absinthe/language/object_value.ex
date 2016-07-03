defmodule Absinthe.Language.ObjectValue do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct [
    fields: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    fields: [Language.ObjectField.t],
    loc: Language.loc_t
  }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Input.Object{
        fields: Absinthe.Blueprint.Draft.convert(node.fields, doc)
      }
    end
  end

end
