defmodule Absinthe.Blueprint.Document.VariableDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Type}

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    default_value: nil,
    source_location: nil,
    # Added by phases
    flags: %{},
    provided_value: nil,
    errors: [],
    schema_node: nil
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          type: Blueprint.TypeReference.t(),
          default_value: Blueprint.Input.t(),
          source_location: nil | Blueprint.Document.SourceLocation.t(),
          provided_value: nil | Blueprint.Input.t(),
          errors: [Absinthe.Phase.Error.t()],
          flags: Blueprint.flags_t(),
          schema_node: Type.t()
        }
end
