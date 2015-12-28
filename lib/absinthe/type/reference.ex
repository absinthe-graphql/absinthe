defmodule Absinthe.Type.Reference do

  @moduledoc false

  @typedoc false
  @type t :: %{module: atom, identifier: atom, name: binary}

  defstruct module: nil, identifier: nil, name: nil

end
