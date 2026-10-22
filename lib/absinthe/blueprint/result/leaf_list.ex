defmodule Absinthe.Blueprint.Result.LeafList do
  @moduledoc false

  # A list result whose elements are leaf values (scalars or enums) with a
  # nullable element type. Such elements never run middleware and cannot be
  # errored or null-trimmed individually, so the list is held as one node of
  # raw values instead of a `Result.Leaf` per element, and is serialized in
  # bulk by `Absinthe.Phase.Document.Result`. Lists with a non-null element
  # type keep the per-element representation to preserve null propagation.

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
          values: [term()],
          errors: [Phase.Error.t()],
          flags: Blueprint.flags_t(),
          extensions: %{any => any}
        }
end
