defmodule Absinthe.Blueprint.Schema.FieldDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    :identifier,
    :type,
    :module,
    description: nil,
    deprecation: nil,
    config: nil,
    triggers: [],
    default_value: nil,
    arguments: [],
    directives: [],
    complexity: nil,
    source_location: nil,
    middleware: [],
    function_ref: nil,
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
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by DSL
          description: nil | String.t(),
          middleware: [any],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  @doc false
  def functions(), do: [:config, :complexity, :middleware, :triggers]
end
