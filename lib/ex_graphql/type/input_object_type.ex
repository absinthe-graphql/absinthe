defmodule ExGraphQL.Type.InputObjectType do
  @type t :: %{name: binary, description: binary, fields: map | (() -> map)}
  defstruct name: nil, description: nil, fields: %{}

  use ExGraphQL.Type.Creation
  def setup(struct), do: {:ok, struct}
end
