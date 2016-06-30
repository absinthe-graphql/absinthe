defmodule Absinthe.Blueprint.IDL.InterfaceTypeDefinition do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
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
    ast_node: nil | Language.InterfaceTypeDefinition.t
  }

  @spec from_ast(Language.InterfaceTypeDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.InterfaceTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc))
    }
  end

end
