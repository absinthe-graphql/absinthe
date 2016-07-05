defmodule Absinthe.Blueprint.Schema.ObjectTypeDefinition do

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
    interfaces: [],
    fields: [],
    directives: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    description: nil | String.t,
    fields: [Blueprint.Schema.FieldDefinition.t],
    interfaces: [String.t],
    directives: [Blueprint.Directive.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
