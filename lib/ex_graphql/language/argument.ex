defmodule ExGraphQL.Language.Argument do

  @type t :: %{name: binary, value: %{value: any}, loc: ExGraphQL.Language.loc_t}
  defstruct name: nil, value: nil, loc: %{}

  defimpl ExGraphQL.Language.Node do
    def children(node) do
      [node.value]
    end
  end

end
