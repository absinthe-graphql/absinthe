defmodule Absinthe.Blueprint.IDL.ScalarTypeDefinition do

  alias Absinthe.{Blueprint, Language}

  defstruct [
    name: nil,
    description: nil,
    directives: [],
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: binary,
    description: nil | binary,
    directives: [Blueprint.Directive.t],
    errors: [Blueprint.Error.t],
    ast_node: Language.t
  }

  def from_ast(%Language.ScalarTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc)),
      ast_node: node,
    }
  end

end
