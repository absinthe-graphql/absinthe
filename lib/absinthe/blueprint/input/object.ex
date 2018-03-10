defmodule Absinthe.Blueprint.Input.Object do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:fields]
  defstruct [
    :source_location,
    fields: [],
    # Added by phases
    flags: %{},
    schema_node: nil,
    errors: []
  ]

  @type t :: %__MODULE__{
          fields: [Blueprint.Input.Field.t()],
          flags: Blueprint.flags_t(),
          schema_node:
            nil
            | Absinthe.Type.InputObject.t()
            | Absinthe.Type.NonNull.t(Absinthe.Type.InputObject.t()),
          source_location: Blueprint.Document.SourceLocation.t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
