defmodule Absinthe.Blueprint.Input.Float do

  @enforce_keys [:value]
  defstruct [
    :value,
    # Added by phases
    flags: [],
    schema_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: float,
    flags: [atom],
    schema_node: nil | Absinthe.Type.t,
    errors: [Absinthe.Phase.Error.t],
  }

end
