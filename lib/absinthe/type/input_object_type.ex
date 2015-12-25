defmodule Absinthe.Type.InputObjectType do
  @type t :: %{name: binary, description: binary, fields: map | (() -> map), type_module: atom}
  defstruct name: nil, description: nil, fields: %{}, type_module: nil
end
