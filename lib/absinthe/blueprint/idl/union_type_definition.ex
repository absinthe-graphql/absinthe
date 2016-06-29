defmodule Absinthe.Blueprint.IDL.UnionTypeDefinition do

  alias Absinthe.{Blueprint, Language}

  defstruct [
    name: nil,
    description: nil,
    directives: [],
    types: [],
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: binary,
    description: nil | binary,
    directives: [Blueprint.Directive.t],
    types: [binary],
    errors: [Blueprint.Error.t],
    ast_node: Language.t
  }

  def from_ast(%Language.UnionTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      types: Enum.map(node.types, &(&1.name)),
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc)),
      ast_node: node
    }
  end

end
