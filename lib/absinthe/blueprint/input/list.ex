defmodule Absinthe.Blueprint.Input.List do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:values]
  defstruct [
    :values,
    # Added by phases
    schema_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    values: [Blueprint.Input.t],
    schema_node: nil | Absinthe.Type.t,
    errors: [Phase.Error.t],
  }

end
