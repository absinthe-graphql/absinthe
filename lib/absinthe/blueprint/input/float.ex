defmodule Absinthe.Blueprint.Input.Float do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:value]
  defstruct [
    :value,
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: float,
    ast_node: nil | Language.FloatValue.t,
    errors: [Absinthe.Phase.Error.t],
  }

  @spec from_ast(Language.FloatValue.t, Language.Document.t) :: t
  def from_ast(%Language.FloatValue{} = node, _doc) do
    %__MODULE__{
      value: node.value,
      ast_node: node
    }
  end

end
