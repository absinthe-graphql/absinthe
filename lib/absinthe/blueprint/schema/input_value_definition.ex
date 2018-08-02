defmodule Absinthe.Blueprint.Schema.InputValueDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  defstruct [
    :name,
    :identifier,
    :type,
    # InputValueDefinitions can have different placements depending on Whether
    # they model an argument definition or a value of an input object type
    # definition
    placement: :argument_definition,
    default_value: nil,
    directives: [],
    # Added by phases
    flags: %{},
    errors: [],
    __reference__: nil
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          type: Blueprint.TypeReference.t(),
          default_value: Blueprint.Input.t(),
          directives: [Blueprint.Directive.t()],
          # The struct module of the parent
          placement: :argument_definition | :input_field_definition,
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
