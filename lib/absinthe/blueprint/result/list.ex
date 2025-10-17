defmodule Absinthe.Blueprint.Result.List do
  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:emitter, :values]
  defstruct [
    :emitter,
    :values,
    errors: [],
    flags: %{},
    extensions: %{},
    continuations: []
  ]

  @type t :: %__MODULE__{
          emitter: Blueprint.Document.Field.t(),
          values: [Blueprint.Execution.node_t()],
          errors: [Phase.Error.t()],
          flags: Blueprint.flags_t(),
          extensions: %{any => any},
          continuations: [Continuation.t()]
        }
end
