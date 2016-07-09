defmodule Absinthe.Blueprint.Document.Operation do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    selections: [],
    variable_definitions: [],
    source_location: nil,
    # Populated by phases
    provided_values: %{},
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: nil | String.t,
    type: :query | :mutation | :subscription,
    selections: [Blueprint.Document.Field.t | Blueprint.Document.Fragment.Inline | Blueprint.Document.Fragment.Spread],
    variable_definitions: [Blueprint.Document.VariableDefinition.t],
    source_location: nil | Blueprint.Document.SourceLocation.t,
    provided_values: %{String.t => nil | Blueprint.Input.t},
    errors: [Absinthe.Phase.Error.t],
  }

end
