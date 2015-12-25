defmodule Absinthe.Type.Enum do
  @type t :: %{name: binary, description: binary, values: %{binary => any}, type_module: atom}
  defstruct name: nil, description: nil, values: %{}, type_module: nil
end
