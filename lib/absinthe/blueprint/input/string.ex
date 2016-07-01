defmodule Absinthe.Blueprint.Input.String do

  alias Absinthe.{Language, Phase}

  @enforce_keys [:value]
  defstruct [
    :value,
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: String.t,
    ast_node: nil | Language.StringValue.t,
    errors: [Phase.Error.t],
  }

  @spec from_ast(Language.StringValue.t, Language.Document.t) :: t
  def from_ast(%Language.StringValue{} = node, _doc) do
    %__MODULE__{
      value: node.value,
      ast_node: node
    }
  end

end
