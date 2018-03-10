defmodule Absinthe.Phase.Document.Validation.NoUnusedVariables do
  @moduledoc false

  # Validates document to ensure that the only variables that are used in a
  # document are defined on the operation.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, input.operations))
    {:ok, result}
  end

  def handle_node(%Blueprint.Document.VariableDefinition{} = node, operations) do
    errors =
      for op <- operations do
        for var <- op.variable_definitions, var.name == node.name do
          if Enum.find(op.variable_uses, &(&1.name == var.name)) do
            []
          else
            [error(node, op)]
          end
        end
      end
      |> List.flatten()

    case errors do
      [] ->
        node

      errors ->
        %{node | errors: errors ++ node.errors}
        |> flag_invalid(:unused)
    end
  end

  def handle_node(node, _) do
    node
  end

  # Generate the error for the node
  @spec error(Blueprint.Document.VariableDefinition.t(), Blueprint.Document.Operation.t()) ::
          Phase.Error.t()
  defp error(node, operation) do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message(node.name, operation.name),
      locations: [node.source_location, operation.source_location]
    }
  end

  @doc """
  Generate an error message for an unused variable.
  """
  @spec error_message(String.t(), nil | String.t()) :: String.t()
  def error_message(name, nil) do
    ~s(Variable "#{name}" is never used.)
  end

  def error_message(name, operation_name) do
    ~s(Variable "#{name}" is never used in operation "#{operation_name}".)
  end
end
