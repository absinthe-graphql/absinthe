defmodule Absinthe.Language.Argument do

  @type t :: %{name: binary, value: %{value: any}, loc: Absinthe.Language.loc_t}
  defstruct name: nil, value: nil, loc: %{}

  defimpl Absinthe.Language.Node do
    def children(node) do
      [node.value]
    end
  end

end
