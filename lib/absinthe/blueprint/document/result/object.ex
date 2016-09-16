defmodule Absinthe.Blueprint.Document.Result.Object do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:emitter, :fields]
  defstruct [
    :emitter,
    :fields,
    # Added by phases
    errors: [],
    flags: %{}
  ]

  @type t :: %__MODULE__{
    emitter: Blueprint.Document.Field.t,
    fields: [Blueprint.Document.Result.t],
    errors: [Phase.Error.t],
    flags: [Blueprint.flag_t]
  }

end
