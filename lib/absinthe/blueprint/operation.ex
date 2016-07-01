defmodule Absinthe.Blueprint.Operation do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    fields: [],
    variable_definitions: [],
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: nil | String.t,
    type: :query | :mutation | :subscription,
    fields: [Blueprint.Field.t],
    variable_definitions: [Blueprint.VariableDefinition.t],
    ast_node: nil | Language.OperationDefinition.t,
    errors: [Absinthe.Phase.Error.t],
  }

  @spec from_ast(Language.OperationDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.OperationDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      type: node.operation,
      variable_definitions: Enum.map(node.variable_definitions, &Blueprint.VariableDefinition.from_ast(&1, doc)),
      fields: Enum.map(node.selection_set.selections, &Blueprint.Field.from_ast(&1, doc)),
      ast_node: node,
    }
  end

end
