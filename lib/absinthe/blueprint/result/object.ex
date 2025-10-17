defmodule Absinthe.Blueprint.Result.Object do
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
    continuations: []
  ]

  @type t :: %__MODULE__{
          emitter: Blueprint.Document.Field.t(),
          fields: [Blueprint.Execution.node_t()],
          errors: [Phase.Error.t()],
          flags: Blueprint.flags_t(),
          extensions: %{any => any},
          continuations: [Continuation.t()]
        }
end
