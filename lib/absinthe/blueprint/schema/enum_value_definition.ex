defmodule Absinthe.Blueprint.Schema.EnumValueDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:value]
  defstruct [
    :value,
    :name,
    :identifier,
    deprecation: nil,
    directives: [],
    source_location: nil,
    description: nil,
    # Added by phases
    flags: %{},
    module: nil,
    errors: [],
    __reference__: nil
  ]

  @type t :: %__MODULE__{
          value: String.t(),
          description: nil | String.t(),
          deprecation: nil | Blueprint.Schema.Deprecation.t(),
          directives: [Blueprint.Directive.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
