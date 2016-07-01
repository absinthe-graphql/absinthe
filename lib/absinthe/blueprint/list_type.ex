defmodule Absinthe.Blueprint.ListType do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:of_type]
  defstruct [
    :of_type,
    ast_node: nil,
    errors: []
  ]

  @type t :: %__MODULE__{
    of_type: Blueprint.type_reference_t,
    ast_node: nil | Language.ListType.t,
    errors: [Absinthe.Phase.Error.t]
  }

  @spec from_ast(Language.ListType.t, Language.Document.t) :: t
  def from_ast(%Language.ListType{} = node, doc) do
    %__MODULE__{
      of_type: Blueprint.type_from_ast_type(node.type, doc),
      ast_node: node
    }
  end

end
