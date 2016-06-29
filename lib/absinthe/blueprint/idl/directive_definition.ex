defmodule Absinthe.Blueprint.IDL.DirectiveDefinition do

  alias Absinthe.{Blueprint, Language}

  defstruct [
    name: nil,
    description: nil,
    directives: [],
    arguments: [],
    locations: [],
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: String.t,
    description: nil,
    arguments: [Absinthe.Blueprint.Argument.t],
    locations: [String.t],
    errors: [Absinthe.Blueprint.Error.t],
    ast_node: Language.DirectiveDefinition.t,
  }

  def from_ast(%Language.DirectiveDefinition{} = node, doc) do
    # TODO: arguments, etc
    %__MODULE__{
      name: node.name,
      ast_node: node,
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc)),
      locations: node.locations
    }
  end

end
