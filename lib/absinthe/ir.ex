defmodule Absinthe.IR do
  require Logger

  alias Absinthe.Language

  alias __MODULE__

  defstruct operations: [], types: [], directives: []
  @type t :: %__MODULE__{} # TODO

  @spec from_ast(Absinthe.Language.Document.t) :: t
  def from_ast(node) do
    do_from_ast(%__MODULE__{}, node.definitions)
  end

  defp do_from_ast(ir, []) do
    ir
  end
  defp do_from_ast(ir, [%Language.OperationDefinition{} = node | rest]) do
    update_in(ir.operations, &[IR.Operation.from_ast(node) | &1])
    |> do_from_ast(rest)
  end
  defp do_from_ast(ir, [%Language.ObjectDefinition{} = node | rest]) do
    update_in(ir.types, &[IR.IDL.ObjectDefinition.from_ast(node) | &1])
    |> do_from_ast(rest)
  end
  defp do_from_ast(ir, [%Language.UnionTypeDefinition{} = node | rest]) do
    update_in(ir.types, &[IR.IDL.UnionTypeDefinition.from_ast(node) | &1])
    |> do_from_ast(rest)
  end
  defp do_from_ast(ir, [%Language.EnumTypeDefinition{} = node | rest]) do
    update_in(ir.types, &[IR.IDL.EnumTypeDefinition.from_ast(node) | &1])
    |> do_from_ast(rest)
  end
  defp do_from_ast(ir, [%Language.DirectiveDefinition{} = node | rest]) do
    update_in(ir.directives, &[IR.IDL.DirectiveDefinition.from_ast(node) | &1])
    |> do_from_ast(rest)
  end
  defp do_from_ast(ir, [definition | rest]) do
    Logger.warn "Could not convert AST definition #{inspect definition} to IR"
    do_from_ast(ir, rest)
  end

end
