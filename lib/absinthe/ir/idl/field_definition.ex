defmodule Absinthe.IR.IDL.FieldDefinition do

  alias Absinthe.{IR, Language}

  defstruct [
    name: nil,
    arguments: [],
    type: nil,
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: binary,
    arguments: IR.IDL.ArgumentDefinition.t,
    type: IR.type_reference_t,
    errors: [IR.Error.t],
    ast_node: Language.t
  }

  def from_ast(node, doc) do
    %__MODULE__{
      name: node.name,
      arguments: Enum.map(node.arguments, &IR.IDL.ArgumentDefinition.from_ast(&1, doc)),
      type: IR.type_from_ast_type(node.type),
      ast_node: node
    }
  end

end
