defmodule Absinthe.Blueprint.Input.Enum do

  alias Absinthe.{Phase}

  @enforce_keys [:value]
  defstruct [
    :value,
    # Added by phases
    schema_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: String.t,
    schema_node: nil | Absinthe.Type.t,
    errors: [Phase.Error.t],
  }

end
