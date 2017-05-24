defmodule Absinthe.Blueprint.Document.Resolution.Object do

  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:emitter, :root_value]
  defstruct [
    :root_value,
    :emitter,
    :fields,
    errors: [],
    flags: %{},
    extensions: %{},
  ]

  @type t :: %__MODULE__{
    emitter: Blueprint.Document.Field.t,
    fields: [Blueprint.Document.Resolution.node_t],
    errors: [Phase.Error.t],
    flags: Blueprint.flags_t,
    extensions: %{any => any},
  }

end
