defmodule Absinthe.Phase.Document.Validation.UniqueOperationNames do
  @moduledoc false

  # Validates document to ensure that all operations have unique names.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    operations =
      for operation <- input.operations do
        process(operation, input.operations)
      end

    result = %{input | operations: operations}
    {:ok, result}
  end

  @spec process(Blueprint.Document.Operation.t(), [Blueprint.Document.Operation.t()]) ::
          Blueprint.Document.Operation.t()
  defp process(%{name: nil} = operation, _) do
    operation
  end

  defp process(operation, operations) do
    if duplicate?(operations, operation) do
      operation
      |> flag_invalid(:duplicate_name)
      |> put_error(error(operation))
    else
      operation
    end
  end

  # Whether a duplicate operation is present
  @spec duplicate?([Blueprint.Document.Operation.t()], Blueprint.Document.Operation.t()) ::
          boolean
  defp duplicate?(operations, operation) do
    Enum.count(operations, &(&1.name == operation.name)) > 1
  end

  # Generate an error for a duplicate operation.
  @spec error(Blueprint.Document.Operation.t()) :: Phase.Error.t()
  defp error(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message(node.name),
      locations: [node.source_location]
    }
  end

  @doc """
  Generate an error message for a duplicate operation.
  """
  @spec error_message(String.t()) :: String.t()
  def error_message(name) do
    ~s(There can only be one operation named "#{name}".)
  end
end
