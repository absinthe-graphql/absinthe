defmodule Absinthe.Blueprint.Directive do

  alias Absinthe.Language

  @enforce_keys [:name]
  defstruct [
    :name,
    arguments: [],
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    arguments: [Absinthe.Blueprint.Argument.t],
    errors: [Absinthe.Blueprint.Error.t],
    ast_node: nil | Language.Directive.t,
  }

  @spec from_ast(Language.Directive.t, Language.Document.t) :: t
  def from_ast(%Language.Directive{} = node, _doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node
    }
  end

end
