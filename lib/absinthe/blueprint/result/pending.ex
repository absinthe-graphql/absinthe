defmodule Absinthe.Blueprint.Result.Pending do
  @moduledoc false

  # Placeholder left in the result tree where a field suspended. The suspended
  # `%Absinthe.Resolution{}` itself is held in the `:pending` pool on
  # `%Absinthe.Blueprint.Execution{}`, keyed by `:ref`. Once every suspended
  # field has resolved, placeholders are replaced by their built results in a
  # single substitution pass.

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:ref, :emitter]
  defstruct [
    :ref,
    :emitter,
    errors: [],
    flags: %{},
    extensions: %{}
  ]

  @type t :: %__MODULE__{
          ref: reference,
          emitter: Blueprint.Document.Field.t(),
          errors: [Phase.Error.t()],
          flags: Blueprint.flags_t(),
          extensions: %{any => any}
        }
end
