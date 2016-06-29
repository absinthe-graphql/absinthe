defmodule Absinthe.IR.IDL.UnionTypeDefinition do

  alias Absinthe.{IR, Language}

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
    directives: [IR.Directive.t],
    types: [binary],
    errors: [IR.Error.t],
    ast_node: Language.t
  }

  def from_ast(%Language.UnionTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      types: Enum.map(node.types, &(&1.name)),
      directives: Enum.map(node.directives, &IR.Directive.from_ast(&1, doc)),
      ast_node: node
    }
  end

end
