defmodule Absinthe.Phase.Document.CurrentOperation do
  @moduledoc """
  Selects the current operation.

  - If an operation name is given, the matching operation is marked as current.
  - If no operation name is provided and the there is only one operation,
    it is set as current.

  Note that no validation occurs in this phase.
  """

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t, nil | String.t) :: {:ok, Blueprint.t}
  def run(input, operation_name) do
    node = Blueprint.postwalk(input, &handle_node(&1, operation_name))
    |> default_operation(operation_name)
    {:ok, node}
  end

  @spec handle_node(Blueprint.node_t, nil | String.t) :: Blueprint.node_t
  defp handle_node(%Blueprint.Document.Operation{name: name} = node, name) do
    %{node | current: true}
  end
  defp handle_node(node, _) do
    node
  end

  @spec default_operation(Blueprint.t, nil | String.t) :: Blueprint.t
  defp default_operation(blueprint, operation_name) do
    ops = do_default_operation(blueprint.operations, operation_name)
    %{blueprint | operations: ops}
  end

  @spec do_default_operation([Blueprint.Document.Operation.t], nil | String.t) :: [Blueprint.Document.Operation.t]
  defp do_default_operation([op], nil) do
    [%{op | current: true}]
  end
  defp do_default_operation(ops, _) do
    ops
  end

end
