defmodule Absinthe.Blueprint.Operation do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    fields: [],
    variable_definitions: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: nil | String.t,
    type: :query | :mutation | :subscription,
    fields: [Blueprint.Field.t],
    variable_definitions: [Blueprint.VariableDefinition.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
