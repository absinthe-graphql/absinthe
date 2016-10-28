defmodule Absinthe.Blueprint.Document.Resolution.Object do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:blueprint, :root_value]
  defstruct [
    :root_value,
    :blueprint,
    :fields,
    # Added by phases
    errors: [],
    flags: %{}
  ]

  @type t :: %__MODULE__{
    blueprint: Blueprint.Document.Field.t,
    fields: [Blueprint.Document.Resolution.node_t],
    errors: [Phase.Error.t],
    flags: [Blueprint.flag_t]
  }

end
