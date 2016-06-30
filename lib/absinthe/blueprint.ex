defmodule Absinthe.Blueprint do
  require Logger

  alias Absinthe.{Blueprint, Language}

  defstruct [
    operations: [],
    types: [],
    directives: []
  ]

  @type t :: %__MODULE__{
    operations: [Blueprint.Operation.t],
    types: [Blueprint.IDL.type_t],
    directives: [Blueprint.IDL.Directive.t],
  }

  @type type_reference_t :: Blueprint.ListType.t | Blueprint.NonNullType.t | Blueprint.NamedType.t

  @spec from_ast(Language.Document.t) :: t
  def from_ast(doc) do
    do_from_ast(%__MODULE__{}, doc.definitions, doc)
  end

  defp do_from_ast(ir, [], _) do
    ir
  end
  defp do_from_ast(ir, [%Language.OperationDefinition{} = node | rest], doc) do
    update_in(ir.operations, &[Blueprint.Operation.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.ObjectTypeDefinition{} = node | rest], doc) do
    update_in(ir.types, &[Blueprint.IDL.ObjectTypeDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.InputObjectTypeDefinition{} = node | rest], doc) do
    update_in(ir.types, &[Blueprint.IDL.InputObjectTypeDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.UnionTypeDefinition{} = node | rest], doc) do
    update_in(ir.types, &[Blueprint.IDL.UnionTypeDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.EnumTypeDefinition{} = node | rest], doc) do
    update_in(ir.types, &[Blueprint.IDL.EnumTypeDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.ScalarTypeDefinition{} = node | rest], doc) do
    update_in(ir.types, &[Blueprint.IDL.ScalarTypeDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.DirectiveDefinition{} = node | rest], doc) do
    update_in(ir.directives, &[Blueprint.IDL.DirectiveDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.InterfaceTypeDefinition{} = node | rest], doc) do
    update_in(ir.types, &[Blueprint.IDL.InterfaceTypeDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [definition | rest], doc) do
    Logger.warn "Could not convert AST definition #{inspect definition} to Blueprint"
    do_from_ast(ir, rest, doc)
  end

  @ast_modules_to_blueprint_modules_for_types %{
    Language.NamedType => Blueprint.NamedType,
    Language.ListType => Blueprint.ListType,
    Language.NonNullType => Blueprint.NonNullType,
  }
  @supported_ast_modules_for_types Map.keys(@ast_modules_to_blueprint_modules_for_types)

  @spec type_from_ast_type(Language.type_reference_t, Language.Document.t) :: Blueprint.type_reference_t
  def type_from_ast_type(%{__struct__: mod} = node, doc) when mod in @supported_ast_modules_for_types do
    @ast_modules_to_blueprint_modules_for_types[mod].from_ast(node, doc)
  end

end
