defmodule Absinthe.Blueprint.Schema.ObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name, :identifier]
  defstruct [
    :name,
    :identifier,
    description: nil,
    interfaces: [],
    fields: [],
    directives: [],
    # Added by phases
    flags: %{},
    imports: [],
    errors: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          identifier: atom,
          description: nil | String.t(),
          fields: [Blueprint.Schema.FieldDefinition.t()],
          interfaces: [String.t()],
          directives: [Blueprint.Directive.t()],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
