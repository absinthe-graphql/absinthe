defmodule Absinthe.Blueprint.Schema.SchemaDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  defstruct description: nil,
            module: nil,
            type_definitions: [],
            directive_definitions: [],
            type_extensions: [],
            directives: [],
            # Added by phases
            flags: %{},
            imports: [],
            errors: [],
            __private__: []

  @type t :: %__MODULE__{
          description: nil | String.t(),
          # types: [Blueprint.Schema.FieldDefinition.t],
          directives: [Blueprint.Directive.t()],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }
end
