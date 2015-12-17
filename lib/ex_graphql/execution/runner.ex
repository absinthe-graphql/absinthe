defmodule ExGraphQL.Execution.Runner do
  @moduledoc """
  Determines the root object to resolve, then runs the correct strategy.
  """

  alias ExGraphQL.Execution
  alias ExGraphQL.Execution.Resolution

  def run(%{selected_operation: nil}) do
    {:ok, %{}}
  end
  def run(%{selected_operation: %{operation: op_type} = operation} = execution) do
    case execute(op_type, operation, execution) do
      {:ok, value, %{errors: errors}} -> {:ok, %{data: value, errors: errors}}
      other -> other
    end
  end

  @spec execute(atom, ExGraphQL.Language.OperationDefinition.t, ExGraphQL.Execution.t) :: {:ok, Execution.result_t} | {:error, any}
  defp execute(:query, operation, %{schema: %{query: query}} = execution) do
    resolution = %Resolution{target: query}
    operation |> IO.inspect
    Resolution.resolve(operation, %{execution | strategy: :serial, resolution: resolution})
  end
  defp execute(:mutation, operation, %{schema: %{mutation: mutation}} = execution) do
    resolution = %Resolution{target: mutation}
    Resolution.resolve(operation, %{execution | strategy: :serial, resolution: resolution})
  end
  defp execute(:subscription, operation, %{schema: %{subscription: subscription}} = execution) do
    resolution = %Resolution{target: subscription}
    Resolution.resolve(operation, %{execution | strategy: :serial, resolution: resolution})
  end
  defp execute(op_type, _operation, _execution) do
    {:error, "No execution strategy for: #{op_type}"}
  end

end
