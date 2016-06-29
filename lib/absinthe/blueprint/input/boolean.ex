defmodule Absinthe.Blueprint.Input.Boolean do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:value, :ast_node]
  defstruct [
    :value,
    :ast_node,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: true | false,
    ast_node: Language.BooleanValue.t,
    errors: [Blueprint.Error.t],
  }

  @spec from_ast(Language.BooleanValue.t, Language.Document.t) :: t
  def from_ast(%Language.BooleanValue{} = node, _doc) do
    %__MODULE__{
      value: node.value,
      ast_node: node
    }
  end

end
