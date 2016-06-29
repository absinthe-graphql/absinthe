defmodule Absinthe.Blueprint.IDL.InputObjectTypeDefinition do

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil, description: nil, interfaces: [], fields: [], directives: [], errors: [], ast_node: nil
  @type t :: %__MODULE__{
    name: binary,
    description: nil | binary,
    fields: [Blueprint.IDL.InputValueDefinition.t],
    directives: [Blueprint.Directive.t],
    errors: [Blueprint.Error.t],
    ast_node: Language.t
  }

  def from_ast(%Language.InputObjectTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      fields: Enum.map(node.fields, &Blueprint.IDL.InputValueDefinition.from_ast(&1, doc)),
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc)),
    }
  end

end
