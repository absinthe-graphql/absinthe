defmodule Absinthe.IR do
  require Logger

  alias Absinthe.Language

  alias __MODULE__

  defstruct operations: [], types: [], directives: []
  @type t :: %__MODULE__{} # TODO

  @spec from_ast(Absinthe.Language.Document.t) :: t
  def from_ast(doc) do
    do_from_ast(%__MODULE__{}, doc.definitions, doc)
  end

  defp do_from_ast(ir, [], _) do
    ir
  end
  defp do_from_ast(ir, [%Language.OperationDefinition{} = node | rest], doc) do
    update_in(ir.operations, &[IR.Operation.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.ObjectDefinition{} = node | rest], doc) do
    update_in(ir.types, &[IR.IDL.ObjectDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.UnionTypeDefinition{} = node | rest], doc) do
    update_in(ir.types, &[IR.IDL.UnionTypeDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.EnumTypeDefinition{} = node | rest], doc) do
    update_in(ir.types, &[IR.IDL.EnumTypeDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.DirectiveDefinition{} = node | rest], doc) do
    update_in(ir.directives, &[IR.IDL.DirectiveDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [%Language.InterfaceTypeDefinition{} = node | rest], doc) do
    update_in(ir.types, &[IR.IDL.InterfaceTypeDefinition.from_ast(node, doc) | &1])
    |> do_from_ast(rest, doc)
  end
  defp do_from_ast(ir, [definition | rest], doc) do
    Logger.warn "Could not convert AST definition #{inspect definition} to IR"
    do_from_ast(ir, rest, doc)
  end

end
