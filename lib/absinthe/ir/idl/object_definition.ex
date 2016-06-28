defmodule Absinthe.IR.IDL.ObjectDefinition do

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

  def from_ast(%Language.ObjectDefinition{} = node) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      interfaces: Enum.map(node.interfaces, &(&1.name)),
      directives: Enum.map(node.directives, &IR.Directive.from_ast/1)
    }
  end

end
