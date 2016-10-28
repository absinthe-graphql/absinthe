defmodule Absinthe.Blueprint.Document.Resolution.Leaf do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:blueprint, :value]
  defstruct [
    :blueprint,
    :value,
    errors: [],
    flags: %{}
  ]

  @type t :: %__MODULE__{
    blueprint: Blueprint.Document.Field.t,
    value: Blueprint.Document.Resolution.node_t,
    errors: [Phase.Error.t],
    flags: [Blueprint.flag_t],
  }

end
