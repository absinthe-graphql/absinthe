defmodule Absinthe.Blueprint.Schema.FieldDefinition do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    deprecation: nil,
    arguments: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    deprecation: nil | Blueprint.Schema.Deprecation.t,
    arguments: Blueprint.Schema.ArgumentDefinition.t,
    type: Blueprint.TypeReference.t,
    errors: [Absinthe.Phase.Error.t]
  }

end
