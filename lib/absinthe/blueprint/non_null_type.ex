defmodule Absinthe.Blueprint.NonNullType do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:of_type, :ast_node]
  defstruct [
    :of_type,
    :ast_node,
    errors: []
  ]

  @type t :: %__MODULE__{
    of_type: Blueprint.type_reference_t,
    ast_node: Language.NonNullType.t,
    errors: [Blueprint.Error.t]
  }

  def from_ast(%Language.NonNullType{} = node, doc) do
    %__MODULE__{
      of_type: Blueprint.type_from_ast_type(node.type, doc),
      ast_node: node
    }
  end

end
