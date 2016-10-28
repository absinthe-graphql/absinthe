defmodule Absinthe.Blueprint.Document.Resolution.List do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:blueprint, :values]
  defstruct [
    :blueprint,
    :values,
    # Added by phases
    errors: [],
    flags: %{}
  ]

  @type t :: %__MODULE__{
    blueprint: Blueprint.Document.Field.t,
    values: [Blueprint.Document.Resolution.node_t],
    errors: [Phase.Error.t],
    flags: [Blueprint.flag_t],
  }

end
