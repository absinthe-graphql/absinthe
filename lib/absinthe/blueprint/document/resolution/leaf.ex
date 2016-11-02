defmodule Absinthe.Blueprint.Document.Resolution.Leaf do

  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:emitter, :value]
  defstruct [
    :emitter,
    :value,
    errors: [],
    flags: %{}
  ]

  @type t :: %__MODULE__{
    emitter: Blueprint.Document.Field.t,
    value: Blueprint.Document.Resolution.node_t,
    errors: [Phase.Error.t],
    flags: [Blueprint.flag_t],
  }

end
