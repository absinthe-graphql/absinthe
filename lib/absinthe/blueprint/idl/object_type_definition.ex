defmodule Absinthe.Blueprint.IDL.ObjectTypeDefinition do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
    interfaces: [],
    fields: [],
    directives: [],
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    description: nil | String.t,
    fields: [Blueprint.IDL.FieldDefinition.t],
    directives: [Blueprint.Directive.t],
    errors: [Blueprint.Error.t],
    interfaces: [String.t],
    ast_node: nil | Language.ObjectTypeDefinition.t,
  }

  @spec from_ast(Language.ObjectTypeDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.ObjectTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      interfaces: Enum.map(node.interfaces, &Blueprint.NamedType.from_ast(&1, doc)),
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc))
    }
  end

end
