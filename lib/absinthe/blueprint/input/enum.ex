defmodule Absinthe.Blueprint.Input.Enum do
  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:value, :source_location]
  defstruct [
    :value,
    :source_location,
    # Added by phases
    flags: %{},
    schema_node: nil,
    errors: []
  ]

  @type t :: %__MODULE__{
          value: String.t(),
          flags: Blueprint.flags_t(),
          schema_node: nil | Absinthe.Type.t(),
          source_location: Blueprint.Document.SourceLocation.t(),
          errors: [Phase.Error.t()]
        }
end
