defmodule Absinthe.Blueprint.Schema.DirectiveDefinition do

  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
    directives: [],
    arguments: [],
    locations: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    description: nil,
    arguments: [Blueprint.ArgumentDefinition.t],
    locations: [String.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
