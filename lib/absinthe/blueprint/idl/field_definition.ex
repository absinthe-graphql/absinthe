defmodule Absinthe.Blueprint.IDL.FieldDefinition do

  alias Absinthe.{Blueprint, Language}

  defstruct [
    name: nil,
    arguments: [],
    type: nil,
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: binary,
    arguments: Blueprint.IDL.ArgumentDefinition.t,
    type: Blueprint.type_reference_t,
    errors: [Blueprint.Error.t],
    ast_node: Language.t
  }

  def from_ast(node, doc) do
    %__MODULE__{
      name: node.name,
      arguments: Enum.map(node.arguments, &Blueprint.IDL.ArgumentDefinition.from_ast(&1, doc)),
      type: Blueprint.type_from_ast_type(node.type),
      ast_node: node
    }
  end

end
