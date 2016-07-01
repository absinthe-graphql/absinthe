defmodule Absinthe.Blueprint.Input.Field do

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
    ast_node: Language.ObjectField.t,
    errors: [Absinthe.Phase.Error.t],
  }

  @spec from_ast(Language.ObjectField.t, Language.Document.t) :: t
  def from_ast(%Language.ObjectField{} = node, doc) do
    %__MODULE__{
      name: node.name,
      value: Blueprint.Input.from_ast(node.value, doc),
      ast_node: node
    }
  end

end
