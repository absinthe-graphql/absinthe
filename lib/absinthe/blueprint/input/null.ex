defmodule Absinthe.Blueprint.Input.Null do
  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  defstruct [
    :source_location,
    # Added by phases
    flags: %{},
    schema_node: nil,
    errors: []
  ]

  @type t :: %__MODULE__{
          flags: Blueprint.flags_t(),
          schema_node: nil | Absinthe.Type.t(),
          source_location: Blueprint.Document.SourceLocation.t(),
          errors: [Phase.Error.t()]
        }
end
