defmodule Absinthe.Blueprint.Schema.InterfaceTypeDefinition do

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
    fields: [],
    directives: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    description: nil | String.t,
    fields: [Blueprint.Schema.FieldDefinition.t],
    directives: [Blueprint.Document.Directive.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
