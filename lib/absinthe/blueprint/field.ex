defmodule Absinthe.Blueprint.Field do

  alias Absinthe.{Blueprint, Language, Type}

  @enforce_keys [:name]
  defstruct [
    :name,
    alias: nil,
    fields: [],
    arguments: [],
    directives: [],
    errors: [],
    ast_node: nil,
    schema_type: nil,
    type_condition: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    fields: [t],
    arguments: [Blueprint.Input.Argument.t],
    directives: [Blueprint.Directive.t],
    errors: [Blueprint.Error.t],
    ast_node: Language.Field.t,
    schema_type: Type.t,
    type_condition: Blueprint.NamedType.t,
  }

  # TODO: Flatten fragments here?
  @spec from_ast(Language.Field.t, Language.Document.t) :: t
  def from_ast(%Language.Field{} = node, doc) do
    %__MODULE__{
      name: node.name,
      alias: node.alias,
      fields: fields_from_ast_selection_set(node.selection_set, doc),
      arguments: Enum.map(node.arguments, &Blueprint.Input.Argument.from_ast(&1, doc)),
      directives: Enum.map(node.directives, &Blueprint.Directive.from_ast(&1, doc)),
      ast_node: node
    }
  end

  @spec fields_from_ast_selection_set(nil | Language.SelectionSet.t, Language.Document.t) :: [t]
  defp fields_from_ast_selection_set(nil, _doc) do
    []
  end
  defp fields_from_ast_selection_set(%Language.SelectionSet{} = node, doc) do
    Enum.map(node.selections, &from_ast(&1, doc))
  end

end
