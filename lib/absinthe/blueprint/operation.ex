defmodule Absinthe.Blueprint.Operation do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name, :type]
  defstruct [
    name: nil,
    type: nil,
    errors: [],
    ast_node: nil,
    fields: []
  ]

  @type t :: %__MODULE__{
    name: nil | String.t,
    type: :query | :mutation | :subscription,
    ast_node: nil | Language.OperationDefinition.t,
    fields: [Blueprint.Field.t]
  }

  @spec from_ast(Language.OperationDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.OperationDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      type: node.operation,
      fields: Enum.map(node.selection_set.selections, &Blueprint.Field.from_ast(&1, doc)),
      ast_node: node,
    }
  end

end
