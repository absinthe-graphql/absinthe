defmodule Absinthe.Blueprint.Error do

  @enforce_keys [:message, :phase]
  defstruct [
    :message,
    :phase
  ]

  @type t :: %__MODULE__{
    message: String.t,
    phase: module,
  }

end
