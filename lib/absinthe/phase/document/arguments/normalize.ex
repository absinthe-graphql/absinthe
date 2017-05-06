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

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(blueprint, _options \\ []) do
    variables = get_variables(blueprint)
    blueprint = Blueprint.prewalk(blueprint, &handle_node(&1, variables))
    {:ok, blueprint}
  end

  defp get_variables(input) do
    case Blueprint.current_operation(input) do
      nil -> %{}
      operation -> Map.new(operation.variable_definitions, &{&1.name, &1.input})
    end
  end

  defp handle_node(%Blueprint.Input.Value{normalized: %Blueprint.Input.Variable{name: variable_name}} = node, variables) do
    case Map.fetch(variables, variable_name) do
      {:ok, var_node} ->
        var_node
      _ -> node
    end
  end
  # Argument not using a variable: Set provided value from the literal value
  defp handle_node(node, _) do
    node
  end

end
