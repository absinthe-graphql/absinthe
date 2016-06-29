defmodule Absinthe.IR.IDL.ObjectTypeDefinition do

  alias Absinthe.{IR, Language}

  defstruct name: nil, description: nil, interfaces: [], fields: [], directives: [], errors: [], ast_node: nil
  @type t :: %__MODULE__{
    name: binary,
    description: nil | binary,
    fields: [IR.IDL.FieldDefinition.t],
    directives: [IR.Directive.t],
    errors: [IR.Error.t],
    interfaces: [binary],
    ast_node: Language.t
  }

  def from_ast(%Language.ObjectTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      interfaces: Enum.map(node.interfaces, &IR.NamedType.from_ast(&1, doc)),
      directives: Enum.map(node.directives, &IR.Directive.from_ast(&1, doc))
    }
  end

end
