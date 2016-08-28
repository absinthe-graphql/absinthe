defmodule Absinthe.Blueprint.Input.Field do

  alias Absinthe.{Blueprint, Type}

  @enforce_keys [:name, :value]
  defstruct [
    :name,
    :value,
    # Added by phases
    flags: [],
    schema_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Blueprint.Input.t,
    flags: [atom],
    schema_node: nil | Type.Field.t,
    errors: [Absinthe.Phase.Error.t],
  }

end
