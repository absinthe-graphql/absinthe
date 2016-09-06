defmodule Absinthe.Phase.Document.Validation.NoUndefinedVariables do
  @moduledoc """
  Validates document to ensure that the only variables that are used in a
  document are defined on the operation.
  """

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    result = Blueprint.prewalk(input, &handle_node(&1, input.variables))
    {:ok, result}
  end

  defp handle_node(node, _) do
    node
  end

  # Generate the error for the node
  @spec error(Blueprint.node_t, String.t, String.t) :: Phase.Error.t
  @spec error(Blueprint.node_t, String.t, nil) :: Phase.Error.t
  defp error(node, name, operation_name \\ nil) do
    Phase.Error.new(
      __MODULE__,
      error_message(name, operation_name),
      node.source_location
    )
  end

  @doc """
  Generate an error message for an undefined variable.
  """
  @spec error_message(String.t, nil | String.t) :: String.t
  def error_message(name, nil) do
    ~s(Variable "#{name}" is not defined.)
  end
  def error_message(name, operation_name) do
    ~s(Variable "#{name}" is not defined by operation "#{operation_name}".)
  end

end
