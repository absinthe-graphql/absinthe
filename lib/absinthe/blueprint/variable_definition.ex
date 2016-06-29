defmodule Absinthe.Blueprint.VariableDefinition do

  alias Absinthe.{Blueprint, Language, Type}

  defstruct [
    name: nil,
    type: nil,
    errors: [],
    default_value: nil,
    ast_node: nil,
    schema_type: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    type: Blueprint.type_reference_t,
    errors: [Blueprint.Error.t],
    default_value: Blueprint.Input.t,
    ast_node: Language.t,
    schema_type: Type.t
  }

  def from_ast(%Language.VariableDefinition{} = node, doc) do
    %__MODULE__{
      name: node.variable.name,
      type: :atom,
    }
  end
end
