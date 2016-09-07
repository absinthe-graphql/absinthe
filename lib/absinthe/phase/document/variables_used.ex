defmodule Absinthe.Phase.Document.VariablesUsed do
  @moduledoc """

  """
  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t) :: {:ok, Blueprint.t}
  def run(input) do
    ops = for op <- input.operations do
      %{op | variable_uses: variables_used(op, input) }
    end
    {:ok, %{input | operations: ops}}
  end

  @spec variables_used(Blueprint.Document.Operation.t, Blueprint.t) :: [Blueprint.Input.Variable.Reference.t]
  defp variables_used(%Blueprint.Document.Operation{} = node, doc) do
    {_, {_, _, vars}} = Blueprint.prewalk(node, {doc.fragments, [], []}, &do_variables_used/2)
    vars
  end

  @target_fragments [
    Blueprint.Document.Fragment.Inline,
    Blueprint.Document.Fragment.Named,
  ]

  defp do_variables_used(%Blueprint.Document.Fragment.Spread{} = node, {fragments, seen, vars} = acc) do
    if node.name in seen do
      {node, acc}
    else
      acc = {fragments, [node.name | seen], vars}
      target_fragment = Enum.find(fragments, &(&1.name == node.name))
      if target_fragment do
        {_, acc} = Blueprint.prewalk(target_fragment, acc, &do_variables_used/2)
        {node, acc}
      else
        {node, acc}
      end
    end
  end
  defp do_variables_used(%Blueprint.Input.Variable{} = node, {fragments, seen, vars}) do
    ref = Blueprint.Input.Variable.to_reference(node)
    {node, {fragments, seen, [ref | vars]}}
  end
  defp do_variables_used(node, acc) do
    {node, acc}
  end

end
