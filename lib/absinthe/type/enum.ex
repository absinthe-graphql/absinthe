defmodule Absinthe.Type.Enum do

  alias Absinthe.Type

  @type t :: %{name: binary, description: binary, values: %{binary => any}, reference: Type.Reference.t}
  defstruct name: nil, description: nil, values: %{}, reference: nil
end
