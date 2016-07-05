defmodule Absinthe.Blueprint.Schema.UnionTypeDefinition do

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
    directives: [],
    types: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    description: nil | String.t,
    directives: [Blueprint.Document.Directive.t],
    types: [Blueprint.TypeReference.Name.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
