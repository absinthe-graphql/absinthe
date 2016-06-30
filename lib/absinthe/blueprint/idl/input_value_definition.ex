defmodule Absinthe.Blueprint.IDL.InputValueDefinition do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    type: Blueprint.type_reference_t,
    errors: [Blueprint.Error.t],
    ast_node: nil | Language.InputValueDefinition.t,
  }

  @spec from_ast(Language.InputValueDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.InputValueDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      type: Blueprint.type_from_ast_type(node.type, doc),
      ast_node: node
    }
  end

end
