defmodule Absinthe.Blueprint.Input.Enum do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:value, :ast_node]
  defstruct [
    :value,
    :ast_node,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: String.t,
    ast_node: Language.EnumValue.t,
    errors: [Blueprint.Error.t],
  }

  @spec from_ast(Language.EnumValue.t, Language.Document.t) :: t
  def from_ast(%Language.EnumValue{} = node, _doc) do
    %__MODULE__{
      value: node.value,
      ast_node: node
    }
  end

end
