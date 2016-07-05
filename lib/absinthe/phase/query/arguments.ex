defmodule Absinthe.Phase.Query.Arguments do
  @moduledoc """
  Populate all arguments in the document with their provided values:

  - If a literal value is provided for an argument, set the `Argument.t`'s
    `provided_value` field to that value.
  - If a variable is provided for an argument, set the `Argument.t`'s
    `provided_value` to the reconciled value for the variable
    (Note: this requires the `Phase.Query.Variables` phase as a
    prerequisite).

  Note that no validation occurs in this phase.
  """

  alias Absinthe.{Blueprint, Phase}

  @spec run(Blueprint.t) :: {:ok, Blueprint.t}
  def run(input) do
    acc = %{provided_values: %{}}
    {node, _} = Blueprint.Mapper.prewalk(input, acc, &handle_node/2)
    {:ok, node}
  end

  @spec handle_node(Blueprint.node_t, map) :: {Blueprint.node_t, map}
  defp handle_node(%Blueprint.Operation{} = node, acc) do
    {
      node,
      %{acc | provided_values: node.provided_values}
    }
  end
  # Argument using a variable: Set provided value
  defp handle_node(%Blueprint.Input.Argument{value: %Blueprint.Input.Variable{name: variable_name}} = node, acc) do
    {
      %{node | provided_value: Map.get(acc.provided_values, variable_name)},
      acc
    }
  end
  # Argument not using a variable: Set provided value from the literal value
  defp handle_node(%Blueprint.Input.Argument{} = node, acc) do
    {
      %{node | provided_value: node.value},
      acc
    }
  end
  defp handle_node(node, acc) do
    {node, acc}
  end

end
