defmodule Absinthe.Language.BooleanValue do
  @moduledoc false

  defstruct [
    value: nil,
    loc: %{}
  ]

  @type t :: %__MODULE__{
    value: boolean,
    loc: Absinthe.Language.loc_t
  }

end
