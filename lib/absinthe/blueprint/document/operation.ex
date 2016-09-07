defmodule Absinthe.Blueprint.Document.Operation do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    current: false,
    selections: [],
    directives: [],
    variable_definitions: [],
    variable_uses: [],
    source_location: nil,
    # Populated by phases
    flags: [],
    schema_node: nil,
    provided_values: %{},
    fields: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: nil | String.t,
    type: :query | :mutation | :subscription,
    current: boolean,
    directives: [Blueprint.Directive.t],
    selections: [Blueprint.Document.selection_t],
    variable_definitions: [Blueprint.Document.VariableDefinition.t],
    variable_uses: [Blueprint.Input.Variable.Reference.t],
    source_location: nil | Blueprint.Document.SourceLocation.t,
    schema_node: nil | Absinthe.Type.Object.t,
    provided_values: %{String.t => nil | Blueprint.Input.t},
    flags: [atom],
    fields: [Blueprint.Document.Field.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
