defmodule Absinthe.Phase.Document.Arguments.Normalize do
  @moduledoc """
  Populate all arguments in the document with their provided values:

  - If a literal value is provided for an argument, set the `Argument.t`'s
    `normalized_value` field to that value.
  - If a variable is provided for an argument, set the `Argument.t`'s
    `normalized_value` to the reconciled value for the variable
    (Note: this requires the `Phase.Document.Variables` phase as a
    prerequisite).

  Note that no validation occurs in this phase.
  """

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _options \\ []) do
    acc = %{provided_values: %{}}
    {node, _} = Blueprint.prewalk(input, acc, &handle_node/2)
    {:ok, node}
  end

  @spec handle_node(Blueprint.node_t, map) :: {Blueprint.node_t, map}
  defp handle_node(%Blueprint.Document.Operation{} = node, acc) do
    {
      node,
      %{acc | provided_values: node.provided_values}
    }
  end
  # Argument using a variable: Set provided value
  defp handle_node(%Blueprint.Input.Value{literal: %Blueprint.Input.Variable{name: variable_name}} = node, acc) do
    {
      %{node | normalized: Map.get(acc.provided_values, variable_name)},
      acc
    }
  end
  # Argument not using a variable: Set provided value from the literal value
  defp handle_node(%Blueprint.Input.Value{} = node, acc) do
    {
      %{node | normalized: node.literal_value},
      acc
    }
  end
  defp handle_node(node, acc) do
    {node, acc}
  end

end
