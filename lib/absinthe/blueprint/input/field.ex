defmodule Absinthe.Blueprint.Input.Field do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name, :value, :ast_node]
  defstruct [
    :name,
    :value,
    :ast_node,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Blueprint.Input.t,
    ast_node: Language.input_t,
    errors: [Blueprint.Error.t],
  }

  def from_ast(node, doc) do
    %__MODULE__{
      name: node.name,
      value: Blueprint.Input.from_ast(node.value, doc),
      ast_node: node
    }
  end

end
