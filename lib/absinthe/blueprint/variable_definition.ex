defmodule Absinthe.Blueprint.VariableDefinition do

  alias Absinthe.{Blueprint, Language, Type}

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    default_value: nil,
    ast_node: nil,
    errors: [],
    schema_type: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    type: Blueprint.type_reference_t,
    default_value: Blueprint.Input.t,
    ast_node: nil | Language.VariableDefinition.t,
    errors: [Blueprint.Error.t],
    schema_type: Type.t,
  }

  @spec from_ast(Language.VariableDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.VariableDefinition{} = node, doc) do
    %__MODULE__{
      name: node.variable.name,
      type: Blueprint.type_from_ast_type(node.type, doc),
      default_value: Blueprint.Input.from_ast(node.default_value, doc),
      ast_node: node
    }
  end
end
