defmodule Absinthe.Phase.Document.Arguments.Normalize do
  @moduledoc false

  # Populate all arguments in the document with their provided values:
  #
  # - If a literal value is provided for an argument, set the `Argument.t`'s
  #   `normalized_value` field to that value.
  # - If a variable is provided for an argument, set the `Argument.t`'s
  #   `normalized_value` to the reconciled value for the variable
  #   (Note: this requires the `Phase.Document.Variables` phase as a
  #   prerequisite).
  #
  # Note that no validation occurs in this phase.

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Input

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    provided_values = get_provided_values(input)
    node = Blueprint.prewalk(input, &handle_node(&1, provided_values))
    {:ok, node}
  end

  @spec get_provided_values(Blueprint.t()) :: map
  defp get_provided_values(input) do
    case Blueprint.current_operation(input) do
      nil -> %{}
      operation -> operation.provided_values
    end
  end

  defp handle_node(
         %Input.RawValue{content: %Input.Variable{name: variable_name}} = node,
         provided_values
       ) do
    %Input.Value{
      normalized: Map.get(provided_values, variable_name),
      raw: node
    }
  end

  # Argument not using a variable: Set provided value from the raw value
  defp handle_node(%Input.RawValue{} = node, _provided_values) do
    %Input.Value{
      normalized: node.content,
      raw: node
    }
  end

  defp handle_node(node, _provided_values) do
    node
  end
end
