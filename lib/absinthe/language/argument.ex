defmodule Absinthe.Language.Argument do

  @moduledoc false

  defstruct [
    name: nil,
    value: nil,
    loc: %{}
  ]

  @type t :: %__MODULE__{
    name: binary,
    value: %{value: any},
    loc: Absinthe.Language.loc_t
  }

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.value]
    end
  end

end
