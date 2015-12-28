defmodule Absinthe.Language.Argument do

  @moduledoc false

  @type t :: %{name: binary, value: %{value: any}, loc: Absinthe.Language.loc_t}
  defstruct name: nil, value: nil, loc: %{}

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.value]
    end
  end

end
