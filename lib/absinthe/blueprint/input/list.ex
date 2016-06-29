defmodule Absinthe.Blueprint.Input.List do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:values, :ast_node]
  defstruct [
    :values,
    :ast_node,
    errors: [],
  ]

  @type t :: %__MODULE__{
    values: [Blueprint.Input.t],
    ast_node: Language.ListValue.t,
    errors: [Blueprint.Error.t],
  }

  @spec from_ast(Language.ListValue.t, Language.Document.t) :: t
  def from_ast(%Language.ListValue{} = node, _doc) do
    %__MODULE__{
      values: node.values,
      ast_node: node
    }
  end


end
