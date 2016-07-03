defmodule Absinthe.Blueprint.IDL.InterfaceTypeDefinition do

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
    fields: [Blueprint.IDL.FieldDefinition.t],
    directives: [Blueprint.Directive.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
