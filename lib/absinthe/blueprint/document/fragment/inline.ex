defmodule Absinthe.Blueprint.Document.Fragment.Inline do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:type_condition]
  defstruct [
    :type_condition,
    selections: [],
    directives: [],
    source_location: nil,
    # Populated by phases
    schema_node: nil,
    complexity: nil,
    flags: %{},
    errors: []
  ]

  @type t :: %__MODULE__{
          directives: [Blueprint.Directive.t()],
          errors: [Absinthe.Phase.Error.t()],
          flags: Blueprint.flags_t(),
          selections: [Blueprint.Document.selection_t()],
          schema_node: nil | Absinthe.Type.t(),
          source_location: nil | Blueprint.Document.SourceLocation.t(),
          type_condition: Blueprint.TypeReference.Name.t()
        }
end
