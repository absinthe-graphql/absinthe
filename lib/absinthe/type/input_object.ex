defmodule Absinthe.Type.InputObject do

  alias Absinthe.Type

  use Type.Fetch

  @type t :: %{name: binary, description: binary, fields: map | (() -> map), reference: Type.Reference.t}
  defstruct name: nil, description: nil, fields: %{}, reference: nil

end
