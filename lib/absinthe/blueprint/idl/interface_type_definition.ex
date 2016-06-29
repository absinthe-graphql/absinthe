defmodule Absinthe.Blueprint.IDL.InterfaceTypeDefinition do

  alias Absinthe.{Blueprint, Language}

  defstruct name: nil, description: nil, fields: [], directives: [], errors: [], ast_node: nil
  @type t :: %__MODULE__{
    name: binary,
    description: nil | binary,
    fields: [Blueprint.IDL.FieldDefinition.t],
    directives: [Blueprint.Directive.t],
    errors: [Blueprint.Error.t],
    ast_node: Language.t
  }

  def from_ast(%Language.InterfaceTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc))
    }
  end

end
