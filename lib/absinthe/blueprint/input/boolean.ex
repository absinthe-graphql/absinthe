defmodule Absinthe.Blueprint.Input.Boolean do

  alias Absinthe.{Blueprint, Language, Phase}

  @enforce_keys [:value]
  defstruct [
    :value,
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: true | false,
    ast_node: nil | Language.BooleanValue.t,
    errors: [Phase.Error.t],
  }

  @spec from_ast(Language.BooleanValue.t, Language.Document.t) :: t
  def from_ast(%Language.BooleanValue{} = node, _doc) do
    %__MODULE__{
      value: node.value,
      ast_node: node
    }
  end

end
