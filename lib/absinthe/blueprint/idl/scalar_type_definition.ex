defmodule Absinthe.Blueprint.IDL.ScalarTypeDefinition do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
    directives: [],
    errors: [],
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    description: nil | String.t,
    directives: [Blueprint.Directive.t],
    errors: [Absinthe.Phase.Error.t],
    ast_node: nil | Language.ScalarTypeDefinition.t,
  }

  @spec from_ast(Language.ScalarTypeDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.ScalarTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc)),
      ast_node: node,
    }
  end

end
