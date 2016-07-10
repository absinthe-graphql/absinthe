defmodule Absinthe.Blueprint.Document.Fragment.Named do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type_condition]
  defstruct [
    :name,
    :type_condition,
    selections: [],
    directives: [],
    source_location: nil,
    # Populated by phases
    fields: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    directives: [Blueprint.Directive.t],
    errors: [Absinthe.Phase.Error.t],
    fields: [Blueprint.Document.Field.t],
    name: String.t,
    selections: [Blueprint.Document.selection_t],
    source_location: nil | Blueprint.Document.SourceLocation.t,
    type_condition: Blueprint.TypeReference.Name.t,
  }

end
