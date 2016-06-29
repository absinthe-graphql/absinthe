defmodule Absinthe.IR.IDL.InputObjectTypeDefinition do

  alias Absinthe.{IR, Language}

  defstruct name: nil, description: nil, interfaces: [], fields: [], directives: [], errors: [], ast_node: nil
  @type t :: %__MODULE__{
    name: binary,
    description: nil | binary,
    fields: [IR.IDL.InputValueDefinition.t],
    directives: [IR.Directive.t],
    errors: [IR.Error.t],
    ast_node: Language.t
  }

  def from_ast(%Language.InputObjectTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      fields: Enum.map(node.fields, &IR.IDL.InputValueDefinition.from_ast(&1, doc)),
      directives: Enum.map(node.directives, &IR.Directive.from_ast(&1, doc)),
    }
  end

end
