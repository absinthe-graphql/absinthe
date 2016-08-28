defmodule Absinthe.Blueprint.Input.Integer do

  alias Absinthe.{Phase}

  @enforce_keys [:value]
  defstruct [
    :value,
    :source_location,
    # Added by phases
    flags: [],
    schema_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: integer,
    flags: [atom],
    source_location: Blueprint.Document.SourceLocation.t,
    schema_node: nil | Absinthe.Type.t,
    errors: [Phase.Error.t],
  }

end
