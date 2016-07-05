defmodule Absinthe.Blueprint.Schema.InputObjectTypeDefinition do

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
    fields: [Blueprint.Schema.InputValueDefinition.t],
    directives: [Blueprint.Directive.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
