defmodule Absinthe.Blueprint.Input.String do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:value, :ast_node]
  defstruct [
    :value,
    :ast_node,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: String.t,
    ast_node: Language.StringValue.t,
    errors: [Blueprint.Error.t],
  }

  @spec from_ast(Language.StringValue.t, Language.Document.t) :: t
  def from_ast(%Language.StringValue{} = node, _doc) do
    %__MODULE__{
      value: node.value,
      ast_node: node
    }
  end

end
