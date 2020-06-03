defmodule Absinthe.Blueprint.Schema.InputValueDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  defstruct [
    :name,
    :identifier,
    :type,
    :module,
    # InputValueDefinitions can have different placements depending on Whether
    # they model an argument definition or a value of an input object type
    # definition
    placement: :argument_definition,
    description: nil,
    default_value: nil,
    default_value_blueprint: nil,
    directives: [],
    source_location: nil,
    # Added by phases
    flags: %{},
    errors: [],
    __reference__: nil,
    __private__: [],
    deprecation: nil
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          type: Blueprint.TypeReference.t(),
          default_value: Blueprint.Input.t(),
          default_value_blueprint: Blueprint.Draft.t(),
          directives: [Blueprint.Directive.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # The struct module of the parent
          placement: :argument_definition | :input_field_definition,
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
