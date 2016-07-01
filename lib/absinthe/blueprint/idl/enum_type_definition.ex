defmodule Absinthe.Blueprint.IDL.EnumTypeDefinition do

  alias Absinthe.{Blueprint, Language}

  defstruct [
    :name,
    values: [],
    directives: [],
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    values: [String.t],
    directives: [Blueprint.Directive.t],
    ast_node: nil | Language.EnumTypeDefinition.t,
    errors: [Absinthe.Phase.Error.t],
  }

  @spec from_ast(Language.EnumTypeDefinition.t, Language.Document.t) :: t
  def from_ast(%Language.EnumTypeDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      values: node.values,
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc)),
      ast_node: node
    }
  end

end
