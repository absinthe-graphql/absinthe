defmodule Absinthe.Type.Enum do
  @type t :: %{name: binary, description: binary, values: %{binary => any}}
  defstruct name: nil, description: nil, values: %{}
end
