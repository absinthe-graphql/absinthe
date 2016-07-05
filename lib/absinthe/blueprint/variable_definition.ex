defmodule Absinthe.Blueprint.VariableDefinition do

  alias Absinthe.{Blueprint, Type}

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    default_value: nil,
    # Added by phases
    provided_value: nil,
    errors: [],
    schema_type: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    type: Blueprint.TypeReference.t,
    default_value: Blueprint.Input.t,
    provided_value: nil | Blueprint.Input.t,
    errors: [Absinthe.Phase.Error.t],
    schema_type: Type.t,
  }

end
