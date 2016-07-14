defmodule Absinthe.Phase.Error do

  @enforce_keys [:message, :phase]
  defstruct [
    :message,
    :phase,
    locations: []
  ]

  @type t :: %__MODULE__{
    message: String.t,
    phase: module,
    locations: [%{line: integer, column: nil | integer}]
  }

end
