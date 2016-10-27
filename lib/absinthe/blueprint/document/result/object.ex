defmodule Absinthe.Blueprint.Document.Result.Object do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:emitter, :root_value]
  defstruct [
    :root_value,
    :emitter,
    :fields,
    # Added by phases
    errors: [],
    flags: %{}
  ]

  @type t :: %__MODULE__{
    emitter: Blueprint.Document.Field.t,
    fields: [Blueprint.Document.Result.node_t],
    errors: [Phase.Error.t],
    flags: [Blueprint.flag_t]
  }

end
