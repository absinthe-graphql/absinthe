defmodule Absinthe.Blueprint.Input.Integer do

  alias Absinthe.{Phase}

  @enforce_keys [:value]
  defstruct [
    :value,
    # Added by phases
    schema_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: integer,
    schema_node: nil | Absinthe.Type.t,
    errors: [Phase.Error.t],
  }

end
