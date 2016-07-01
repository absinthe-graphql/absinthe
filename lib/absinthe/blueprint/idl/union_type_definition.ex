defmodule Absinthe.Blueprint.IDL.UnionTypeDefinition do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
    directives: [],
    types: [],
    errors: [],
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    description: nil | String.t,
    directives: [Blueprint.Directive.t],
    types: [Blueprint.NamedType.t],
    errors: [Absinthe.Phase.Error.t],
    ast_node: nil | Language.UnionTypeDefinition.t,
  }

  @spec from_ast(Language.UnionTypeDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.UnionTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      types: Enum.map(node.types, &Blueprint.NamedType.from_ast(&1, doc)),
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc)),
      ast_node: node
    }
  end

end
