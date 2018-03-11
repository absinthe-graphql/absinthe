defmodule Absinthe.Blueprint.Input.Float do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:value]
  defstruct [
    :value,
    :source_location,
    # Added by phases
    flags: %{},
    schema_node: nil,
    errors: []
  ]

  @type t :: %__MODULE__{
          value: float,
          flags: Blueprint.flags_t(),
          source_location: Blueprint.Document.SourceLocation.t(),
          schema_node: nil | Absinthe.Type.t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
