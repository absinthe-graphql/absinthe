defmodule Absinthe.Blueprint.Schema.InterfaceTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
    fields: [],
    directives: [],
    # Added by phases
    flags: %{},
    errors: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          fields: [Blueprint.Schema.FieldDefinition.t()],
          directives: [Blueprint.Directive.t()],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
