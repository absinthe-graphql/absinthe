defmodule Absinthe.Blueprint.IDL.InputObjectTypeDefinition do

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
    fields: [Blueprint.IDL.InputValueDefinition.t],
    directives: [Blueprint.Directive.t],
    errors: [Absinthe.Phase.Error.t],
    ast_node: nil | Language.InputObjectTypeDefinition.t
  }

  @spec from_ast(Language.InputObjectTypeDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.InputObjectTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      fields: Enum.map(node.fields, &Blueprint.IDL.InputValueDefinition.from_ast(&1, doc)),
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc)),
    }
  end

end
