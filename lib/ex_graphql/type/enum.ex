defmodule ExGraphQL.Type.Enum do
  @type t :: %{name: binary, description: binary, values: %{binary => any}}
  defstruct name: nil, description: nil, values: %{}

  use ExGraphQL.Type.Creation
  def setup(struct), do: {:ok, struct}
end
