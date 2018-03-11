defmodule Absinthe.Blueprint.Schema.FieldDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    deprecation: nil,
    arguments: [],
    directives: [],
    # Added by phases
    flags: %{},
    errors: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          deprecation: nil | Blueprint.Schema.Deprecation.t(),
          arguments: [Blueprint.Schema.InputValueDefinition.t()],
          type: Blueprint.TypeReference.t(),
          directives: [Blueprint.Directive.t()],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
