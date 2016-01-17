defmodule Absinthe.Execution.Runner do
  # Determines the root object to resolve, then runs the correct strategy.

  @moduledoc false

  alias Absinthe.Execution
  alias Absinthe.Execution.Resolution

  @doc false
  @spec run(Execution.t) :: {:ok, Execution.result_t} | {:error, any}
  def run(%{selected_operation: nil}) do
    {:ok, %{}}
  end
  def run(%{selected_operation: %{operation: op_type} = operation} = execution) do
    case execute(op_type, operation, execution) do
      {:ok, value, %{errors: errors}} -> {:ok, %{data: value, errors: errors} |> collapse}
      other -> other
    end
  end

  @spec execute(atom, Absinthe.Language.OperationDefinition.t, Absinthe.Execution.t) :: {:ok, Execution.result_t} | {:error, any}
  defp execute(:query, operation, %{schema: %{query: query}} = execution) do
    resolution = %Resolution{target: query}
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

  # Remove unused `data` and `errors` entries from a result
  @spec collapse(Execution.result_t) :: Execution.result_t
  defp collapse(%{errors: []} = result) do
    result
    |> Map.delete(:errors)
    |> collapse
  end
  defp collapse(result) do
    result
  end

end
