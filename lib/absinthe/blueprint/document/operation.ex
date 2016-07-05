defmodule Absinthe.Blueprint.Document.Operation do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    fields: [],
    variable_definitions: [],
    source_location: nil,
    # Populated by phases
    provided_values: %{},
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: nil | String.t,
    type: :query | :mutation | :subscription,
    fields: [Blueprint.Document.Field.t],
    variable_definitions: [Blueprint.Document.VariableDefinition.t],
    source_location: nil | Blueprint.Document.SourceLocation.t,
    provided_values: %{String.t => nil | Blueprint.Input.t},
    errors: [Absinthe.Phase.Error.t],
  }

end
