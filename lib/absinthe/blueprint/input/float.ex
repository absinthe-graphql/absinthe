defmodule Absinthe.Blueprint.Input.Float do

  @enforce_keys [:value]
  defstruct [
    :value,
    # Added by phases
    schema_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: float,
    schema_node: nil | Absinthe.Type.t,
    errors: [Absinthe.Phase.Error.t],
  }

end
