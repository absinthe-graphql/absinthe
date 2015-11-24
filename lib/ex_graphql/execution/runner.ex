defmodule ExGraphQL.Execution.Runner do
  @moduledoc """
  Determines the root object to resolve, then runs the correct strategy.
  """

  alias ExGraphQL.Execution.Strategy
  alias ExGraphQL.Execution.Resolution

  def run(%{selected_operation: nil}) do
    {:ok, %{}}
  end
  def run(%{selected_operation: %{operation: op_type} = operation} = execution) do
    execute(op_type, operation, execution)
  end

  @spec execute(atom, ExGraphQL.Execution.t) :: {:ok, map} | {:error, any}
  defp execute(:query, operation, %{schema: %{query: query}} = execution) do
    Resolution.resolve(operation, query, %{execution | strategy: :serial})
  end
  defp execute(:mutation, operation, %{schema: %{mutation: mutation}} = execution) do
    Resolution.resolve(operation, mutation, %{execution | strategy: :serial})
  end
  defp execute(:subscription, %{schema: %{subscription: subscription}} = execution) do
    Resolution.resolve(operation, subscription, %{execution | strategy: :serial})
  end
  defp execute(op_type, _operation, _execution) do
    {:error, "No execution strategy for: #{op_type}"}
  end

end
