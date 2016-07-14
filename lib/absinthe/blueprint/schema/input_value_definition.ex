defmodule Absinthe.Blueprint.Schema.InputValueDefinition do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    default_value: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    type: Blueprint.TypeReference.t,
    default_value: Blueprint.Input.t,
    errors: [Absinthe.Phase.Error.t],
  }

end
