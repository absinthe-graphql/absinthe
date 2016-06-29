defmodule Absinthe.Blueprint.IDL.InputValueDefinition do

  alias Absinthe.{Blueprint, Language}

  defstruct [
    name: nil,
    type: nil,
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: String.t,
    type: Blueprint.type_reference_t,
    errors: [Blueprint.Error.t],
    ast_node: Language.t
  }

  def from_ast(node, doc) do
    %__MODULE__{
      name: node.name,
      type: Blueprint.type_from_ast_type(node.type, doc),
      ast_node: node
    }
  end

end
