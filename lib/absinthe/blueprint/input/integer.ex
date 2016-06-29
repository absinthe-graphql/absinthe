defmodule Absinthe.Blueprint.Input.Integer do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:value, :ast_node]
  defstruct [
    :value,
    :ast_node,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: integer,
    ast_node: Language.IntValue.t,
    errors: [Blueprint.Error.t],
  }

  @spec from_ast(Language.IntValue.t, Language.Document.t) :: t
  def from_ast(%Language.IntValue{} = node, _doc) do
    %__MODULE__{
      value: node.value,
      ast_node: node
    }
  end

end
