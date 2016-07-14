defmodule Absinthe.Blueprint.Document.Field do

  alias Absinthe.{Blueprint, Phase, Type}

  @enforce_keys [:name]
  defstruct [
    :name,
    alias: nil,
    selections: [],
    arguments: [],
    directives: [],
    # Added by phases
    errors: [],
    source_location: nil,
    type_conditions: [],
    schema_type: nil,
    fields: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    selections: [Blueprint.Document.selection_t],
    arguments: [Blueprint.Input.Argument.t],
    directives: [Blueprint.Directive.t],
    errors: [Phase.Error.t],
    fields: [Blueprint.Document.Field.t],
    source_location: nil | Blueprint.Document.SourceLocation.t,
    type_conditions: [Blueprint.TypeReference.Name],
    schema_type: Type.t
  }

end
