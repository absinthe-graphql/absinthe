defmodule Absinthe.Blueprint.IDL.ObjectTypeDefinition do

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil, description: nil, interfaces: [], fields: [], directives: [], errors: [], ast_node: nil
  @type t :: %__MODULE__{
    name: binary,
    description: nil | binary,
    fields: [Blueprint.IDL.FieldDefinition.t],
    directives: [Blueprint.Directive.t],
    errors: [Blueprint.Error.t],
    interfaces: [binary],
    ast_node: Language.t
  }

  def from_ast(%Language.ObjectTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      interfaces: Enum.map(node.interfaces, &Blueprint.NamedType.from_ast(&1, doc)),
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc))
    }
  end

end
