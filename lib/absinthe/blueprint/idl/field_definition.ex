defmodule Absinthe.Blueprint.IDL.FieldDefinition do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    arguments: [],
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    arguments: Blueprint.IDL.ArgumentDefinition.t,
    type: Blueprint.type_reference_t,
    errors: [Blueprint.Error.t],
    ast_node: nil | Language.FieldDefinition.t
  }

  @spec from_ast(Language.FieldDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.FieldDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      arguments: Enum.map(node.arguments, &Blueprint.IDL.ArgumentDefinition.from_ast(&1, doc)),
      type: Blueprint.type_from_ast_type(node.type, doc),
      ast_node: node
    }
  end

end
