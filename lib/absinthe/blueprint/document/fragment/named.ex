defmodule Absinthe.Blueprint.Document.Fragment.Named do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type_condition]
  defstruct [
    :name,
    :type_condition,
    fields: [],
    directives: [],
    source_location: nil,
    # Populated by phases
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    fields: [Blueprint.Document.Field.t],
    directives: [Blueprint.Directive.t],
    type_condition: Blueprint.TypeReference.Name.t,
    source_location: nil | Blueprint.Document.SourceLocation.t,
    errors: [Absinthe.Phase.Error.t],
  }

end
