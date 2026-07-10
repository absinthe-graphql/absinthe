defmodule Absinthe.Blueprint.Result.LeafList do
  @moduledoc false

  # A list whose elements are leaf values (scalars or enums) with nullable
  # element type. Because such elements never run middleware and can never be
  # errored or null-trimmed individually, the whole list is held as one node of
  # raw values instead of wrapping each element in a `Result.Leaf`. Serialization
  # happens in bulk in `Absinthe.Phase.Document.Result`. Lists with a non-null
  # element type keep the per-element `Result.Leaf` representation so the
  # null-propagation machinery is unchanged.

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:emitter]
  defstruct [
    :emitter,
    values: [],
    errors: [],
    flags: %{},
    extensions: %{}
  ]

  @type t :: %__MODULE__{
          emitter: Blueprint.Document.Field.t(),
          values: [Blueprint.Execution.node_t()],
          errors: [Phase.Error.t()],
          flags: Blueprint.flags_t(),
          extensions: %{any => any}
        }
end
