defmodule Absinthe.Language.StringValue do

  @moduledoc false

  defstruct [
    value: nil,
    loc: %{}
  ]

  @type t :: %__MODULE__{
    value: binary,
    loc: Absinthe.Language.loc_t
  }

end
