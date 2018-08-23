defmodule Absinthe.Blueprint.Schema.FieldDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :identifier,
    :type,
    :module,
    description: nil,
    deprecation: nil,
    config_ast: nil,
    default_value: nil,
    arguments: [],
    directives: [],
    complexity: nil,
    # Added by DSL
    description: nil,
    middleware_ast: [],
    # Added by phases
    flags: %{},
    errors: [],
    __reference__: nil,
    __private__: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          identifier: atom,
          description: nil | String.t(),
          deprecation: nil | Blueprint.Schema.Deprecation.t(),
          arguments: [Blueprint.Schema.InputValueDefinition.t()],
          type: Blueprint.TypeReference.t(),
          directives: [Blueprint.Directive.t()],
          # Added by DSL
          description: nil | String.t(),
          middleware_ast: [any],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
