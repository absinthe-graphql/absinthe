defmodule Absinthe.Blueprint.IDL.DirectiveDefinition do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name]
  defstruct [
    :name,
    description: nil,
    directives: [],
    arguments: [],
    locations: [],
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    description: nil,
    arguments: [Blueprint.ArgumentDefinition.t],
    locations: [String.t],
    errors: [Absinthe.Phase.Error.t],
    ast_node: nil | Language.DirectiveDefinition.t,
  }

  @spec from_ast(Language.DirectiveDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.DirectiveDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      ast_node: node,
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc)),
      arguments: Enum.map(node.arguments, &Blueprint.IDL.ArgumentDefinition.from_ast(&1, doc)),
      locations: node.locations
    }
  end

end
