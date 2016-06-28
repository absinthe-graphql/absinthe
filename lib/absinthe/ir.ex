defmodule Absinthe.IR do

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
    update_in(ir.types, &[IR.IDL.Object.from_ast(node) | &1])
    |> do_from_ast(rest)
  end
  defp do_from_ast(ir, [%Language.DirectiveDefinition{} = node | rest]) do
    update_in(ir.directives, &[IR.IDL.Directive.from_ast(node) | &1])
    |> do_from_ast(rest)
  end
  defp do_from_ast(ir, [_ | rest]) do
    do_from_ast(ir, rest)
  end

end
