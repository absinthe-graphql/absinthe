defmodule Absinthe.Blueprint.Document.Result.List do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:emitter, :values]
  defstruct [
    :emitter,
    :values,
    # Added by phases
    errors: [],
    flags: %{}
  ]

  @type t :: %__MODULE__{
    emitter: Blueprint.Document.Field.t,
    values: [Blueprint.Document.Result.node_t],
    errors: [Phase.Error.t],
    flags: [Blueprint.flag_t],
  }

end
