defmodule Absinthe.Type.Reference do
  @moduledoc false

  @typedoc false
  @type t :: %__MODULE__{module: atom, identifier: atom, name: binary}

  defstruct module: nil, identifier: nil, name: nil
end
