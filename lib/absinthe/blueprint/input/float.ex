defmodule Absinthe.Blueprint.Input.Float do

  @enforce_keys [:value]
  defstruct [
    :value,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: float,
    errors: [Absinthe.Phase.Error.t],
  }

end
