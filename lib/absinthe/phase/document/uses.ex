defmodule Absinthe.Phase.Document.Uses do
  @moduledoc false

  # Tracks uses of:
  # - Variables
  # - Fragments

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @typep acc_t :: %{
           fragments_available: [Blueprint.Document.Fragment.Named.t()],
           fragments: [Blueprint.Document.Fragment.Named.Use.t()],
           variables: [Blueprint.Input.Variable.Use.t()]
         }

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    ops = Enum.map(input.operations, &add_uses(&1, input))
    node = %{input | operations: ops}
    {:ok, node}
  end

  @spec add_uses(Blueprint.Document.Operation.t(), Blueprint.t()) ::
          Blueprint.Document.Operation.t()
  defp add_uses(%Blueprint.Document.Operation{} = node, doc) do
    acc = %{
      fragments_available: doc.fragments,
      fragments: [],
      variables: []
    }

    {_, acc} = Blueprint.prewalk(node, acc, &handle_use/2)

    %{
      node
      | fragment_uses: acc.fragments ++ node.fragment_uses,
        variable_uses: acc.variables ++ node.variable_uses
    }
  end

  @spec handle_use(Blueprint.node_t(), acc_t) :: {Blueprint.node_t(), acc_t}
  defp handle_use(%Blueprint.Document.Fragment.Spread{} = node, acc) do
    if uses?(acc.fragments, node) do
      {node, acc}
    else
      target_fragment = Enum.find(acc.fragments_available, &(&1.name == node.name))

      if target_fragment do
        acc = acc |> put_use(target_fragment)
        {_, acc} = Blueprint.prewalk(target_fragment, acc, &handle_use/2)
        {node, acc}
      else
        {node, acc}
      end
    end
  end

  defp handle_use(%Blueprint.Input.Variable{} = node, acc) do
    {node, put_use(acc, node)}
  end

  defp handle_use(node, acc) do
    {node, acc}
  end

  @spec uses?([Blueprint.use_t()], Blueprint.Document.Fragment.Spread.t()) :: boolean
  defp uses?(list, node) do
    Enum.find(list, &(&1.name == node.name))
  end

  @spec put_use(acc_t, Blueprint.node_t()) :: acc_t
  defp put_use(acc, %Blueprint.Input.Variable{} = node) do
    ref = Blueprint.Input.Variable.to_use(node)
    update_in(acc.variables, &[ref | &1])
  end

  defp put_use(acc, %Blueprint.Document.Fragment.Named{} = node) do
    ref = Blueprint.Document.Fragment.Named.to_use(node)
    update_in(acc.fragments, &[ref | &1])
  end
end
