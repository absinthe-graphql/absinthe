defmodule Absinthe.Blueprint.NamedType do

  alias Absinthe.{Phase, Language}

  @enforce_keys [:name]
  defstruct [
    :name,
    ast_node: nil,
    errors: []
  ]

  @type t :: %__MODULE__{
    name: String.t,
    ast_node: nil | Language.NamedType.t,
    errors: [Phase.Error.t]
  }

  @spec from_ast(Language.NamedType.t, Language.Document.t) :: t
  def from_ast(%Language.NamedType{name: name} = node, _doc) do
    %__MODULE__{
      name: name,
      ast_node: node
    }
  end

end
