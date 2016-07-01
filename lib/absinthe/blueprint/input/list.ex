defmodule Absinthe.Blueprint.Input.List do

  alias Absinthe.{Blueprint, Language, Phase}

  @enforce_keys [:values]
  defstruct [
    :values,
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    values: [Blueprint.Input.t],
    ast_node: nil | Language.ListValue.t,
    errors: [Phase.Error.t],
  }

  @spec from_ast(Language.ListValue.t, Language.Document.t) :: t
  def from_ast(%Language.ListValue{} = node, _doc) do
    %__MODULE__{
      values: node.values,
      ast_node: node
    }
  end

end
