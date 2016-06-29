defmodule Absinthe.Blueprint.Error do
  defstruct [
    message: nil,
    phase: nil,
  ]

  @type t :: %__MODULE__{
    message: String.t,
    phase: atom,
  }
end
