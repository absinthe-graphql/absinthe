defmodule Absinthe.Blueprint.Input.Field do
  @moduledoc false

  alias Absinthe.{Blueprint, Type}

  @enforce_keys [:name, :input_value]
  defstruct [
    :name,
    :input_value,
    # Added by phases
    flags: %{},
    source_location: nil,
    schema_node: nil,
    errors: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          input_value: Blueprint.Input.Value.t(),
          flags: Blueprint.flags_t(),
          schema_node: nil | Type.Field.t(),
          source_location: Blueprint.Document.SourceLocation.t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
