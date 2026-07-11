defmodule Absinthe.Blueprint.Result.LeafList do
  @moduledoc false

  # Holds a list of nullable scalar or enum values as a single node, rather than
  # one `Result.Leaf` per element. That's safe because these elements never run
  # middleware and can't be null-trimmed on their own. Lists with non-null
  # elements keep the per-element form. The values are serialized in bulk by
  # `Absinthe.Phase.Document.Result`.

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
          values: [term],
          errors: [Phase.Error.t()],
          flags: Blueprint.flags_t(),
          extensions: %{any => any}
        }
end
