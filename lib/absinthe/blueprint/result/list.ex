defmodule Absinthe.Blueprint.Result.List do
  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:emitter, :values]
  defstruct [
    :emitter,
    :values,
    errors: [],
    flags: %{},
    extensions: %{}
  ]

  @type t :: %__MODULE__{
          emitter: Blueprint.Document.Field.t(),
          values: [Blueprint.Document.Resolution.node_t()],
          errors: [Phase.Error.t()],
          flags: Blueprint.flags_t(),
          extensions: %{any => any}
        }
end
