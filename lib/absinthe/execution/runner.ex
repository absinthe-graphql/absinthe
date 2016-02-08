defmodule Absinthe.Execution.Runner do
  # Determines the root object to resolve, then runs the correct strategy.

  @moduledoc false

  alias Absinthe.Execution
  alias Absinthe.Execution.Resolution
  alias Absinthe.Schema

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
  defp execute(op_type, operation, %{schema: schema} = execution) do
    resolution = %Resolution{target: Absinthe.Schema.lookup_type(schema, op_type)}
    Resolution.resolve(operation, %{execution | strategy: :serial, resolution: resolution})
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
