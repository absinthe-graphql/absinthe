defmodule Absinthe.Blueprint.Input.Integer do

  alias Absinthe.{Phase, Language}

  @enforce_keys [:value]
  defstruct [
    :value,
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: integer,
    ast_node: nil | Language.IntValue.t,
    errors: [Phase.Error.t],
  }

  @spec from_ast(Language.IntValue.t, Language.Document.t) :: t
  def from_ast(%Language.IntValue{} = node, _doc) do
    %__MODULE__{
      value: node.value,
      ast_node: node
    }
  end

end
