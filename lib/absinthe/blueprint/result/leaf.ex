defmodule Absinthe.Blueprint.Result.Leaf do
  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:emitter, :value]
  defstruct [
    :emitter,
    :value,
    errors: [],
    flags: %{},
    extensions: %{}
  ]

  @type t :: %__MODULE__{
          emitter: Blueprint.Document.Field.t(),
          value: Blueprint.Document.Resolution.node_t(),
          errors: [Phase.Error.t()],
          flags: Blueprint.flags_t(),
          extensions: %{any => any}
        }
end
