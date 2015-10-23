defmodule ExGraphQL.Type.InterfaceType do
  defstruct name: nil, description: nil, fields: nil, resolveType: nil

  use ExGraphQL.Type.Creation
  def setup(struct), do: {:ok, struct}
end
