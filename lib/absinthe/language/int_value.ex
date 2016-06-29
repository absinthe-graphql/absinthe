defmodule Absinthe.Language.IntValue do
  @moduledoc false

  defstruct [
    value: nil
  ]

  @type t :: %__MODULE__{
    value: integer
  }

end
