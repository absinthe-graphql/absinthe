defmodule Absinthe.Blueprint.Document.Resolution.List do

  @moduledoc false

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
    values: [Blueprint.Document.Resolution.node_t],
    errors: [Phase.Error.t],
    flags: [Blueprint.flag_t],
  }

end
