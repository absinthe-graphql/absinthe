defmodule Absinthe.Blueprint.Schema.SchemaDeclaration do
  @moduledoc false

  alias Absinthe.Blueprint

  defstruct description: nil,
            module: nil,
            field_definitions: [],
            directives: [],
            source_location: nil,
            # Added by phases
            flags: %{},
            errors: [],
            __reference__: nil,
            __private__: []

  @type t :: %__MODULE__{
          description: nil | String.t(),
          module: nil | module(),
          directives: [Blueprint.Directive.t()],
          field_definitions: [Blueprint.Schema.FieldDefinition.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  defimpl Inspect do
    defdelegate inspect(term, options),
      to: Absinthe.Schema.Notation.SDL.Render
  end
end
