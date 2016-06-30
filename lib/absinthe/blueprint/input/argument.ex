defmodule Absinthe.Blueprint.Input.Argument do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name, :value]
  defstruct [
    :name,
    :value,
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Blueprint.Input.t,
    errors: [Blueprint.Error.t],
    ast_node: nil | Language.Argument.t,
  }

  @spec from_ast(Language.Argument.t, Language.Document.t) :: t
  def from_ast(%Language.Argument{} = node, doc) do
    %__MODULE__{
      name: node.name,
      value: Blueprint.Input.from_ast(node.value, doc),
      ast_node: node
    }
  end

end
