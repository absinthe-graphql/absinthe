defmodule ExGraphQL.Type.ObjectType do
  @type t :: %{name: binary, description: binary, fields: map | (() -> map), interfaces: [ExGraphQL.Type.Interface.t], is_type_of: ((any) -> boolean)}
  defstruct name: nil, description: nil, fields: nil, interfaces: [], is_type_of: nil

  use ExGraphQL.Type.Creation
  def setup(struct), do: {:ok, struct}
end
