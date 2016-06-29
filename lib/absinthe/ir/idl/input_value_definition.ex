defmodule Absinthe.IR.IDL.InputValueDefinition do

  alias Absinthe.{IR, Language}

  defstruct [
    name: nil,
    type: nil,
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: binary,
    type: IR.type_reference_t,
    errors: [IR.Error.t],
    ast_node: Language.t
  }

  def from_ast(node, doc) do
    %__MODULE__{
      name: node.name,
      type: IR.type_from_ast_type(node.type),
      ast_node: node
    }
  end

end
