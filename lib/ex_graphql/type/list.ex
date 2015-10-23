defmodule ExGraphQL.Type.List do
  @type t :: %{of_type: ExGraphQL.Type.t}
  defstruct of_type: nil

  use ExGraphQL.Type.Creation
  def setup(struct), do: {:ok, struct}
end
