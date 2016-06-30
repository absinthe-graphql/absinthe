defmodule Absinthe.Blueprint.Input.Variable do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name]
  defstruct [
    :name,
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    ast_node: nil | Language.Variable.t,
    errors: [Blueprint.Error.t],
  }

  @spec from_ast(Language.Variable.t, Language.Document.t) :: t
  def from_ast(%Language.Variable{} = node, _doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node
    }
  end

end
