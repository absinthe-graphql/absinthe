defmodule Absinthe.IR.IDL.InterfaceTypeDefinition do

  alias Absinthe.{IR, Language}

  defstruct name: nil, description: nil, fields: [], directives: [], errors: [], ast_node: nil
  @type t :: %__MODULE__{
    name: binary,
    description: nil | binary,
    fields: [IR.IDL.FieldDefinition.t],
    directives: [IR.Directive.t],
    errors: [IR.Error.t],
    ast_node: Language.t
  }

  def from_ast(%Language.InterfaceTypeDefinition{} = node) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      directives: Enum.map(node.directives, &IR.Directive.from_ast/1)
    }
  end

end
