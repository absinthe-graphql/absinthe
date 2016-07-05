defmodule Absinthe.Blueprint.Schema.ScalarTypeDefinition do

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
    directives: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    description: nil | String.t,
    directives: [Blueprint.Directive.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
