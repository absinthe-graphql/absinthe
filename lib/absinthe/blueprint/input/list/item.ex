defmodule Absinthe.Blueprint.Input.List.Item do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:input_value]
  defstruct [
    :input_value,
    :value,
    :source_location,
    # Added by phases
    flags: %{},
    schema_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    input_value: Blueprint.Input.Value.t,
    value: any,
    flags: Blueprint.flags_t,
    schema_node: nil | Absinthe.Type.t,
    source_location: Blueprint.Document.SourceLocation.t,
    errors: [Phase.Error.t],
  }

end
