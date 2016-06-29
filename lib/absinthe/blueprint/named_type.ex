defmodule Absinthe.Blueprint.NamedType do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name, :ast_node]
  defstruct [
    :name,
    :ast_node,
    errors: []
  ]

  @type t :: %__MODULE__{
    name: String.t,
    ast_node: Language.NamedType.t,
    errors: [Blueprint.Error.t]
  }

  def from_ast(%Language.NamedType{name: name} = node, _doc) do
    %__MODULE__{
      name: name,
      ast_node: node
    }
  end

end
