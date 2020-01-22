defmodule Absinthe.Phase.Document.Validation.SelectedCurrentOperation do
  @moduledoc false

  # Validates an operation name was provided when needed.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, options \\ []) do
    result =
      case {Blueprint.current_operation(input), length(input.operations)} do
        {nil, count} when count >= 1 ->
          operation_name = Keyword.get(options, :operation_name)

          input
          |> flag_invalid(:no_current_operation)
          |> put_error(error(operation_name, count))

        _ ->
          input
      end

    {:ok, result}
  end

  # Generate the error
  @spec error(String.t(), integer()) :: Phase.Error.t()
  defp error(operation_name, operation_count) do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message(operation_name, operation_count)
    }
  end

  def error_message(nil, _) do
    """
    Must provide a valid operation name if query contains multiple operations.

    No operation name was given.
    """
  end

  def error_message(operation_name, 1) do
    """
    The provided operation name did not match the operation in the query.

    The provided operation name was: #{inspect(operation_name)}
    """
  end

  def error_message(operation_name, _) do
    """
    Must provide a valid operation name if query contains multiple operations.

    The provided operation name was: #{inspect(operation_name)}
    """
  end
end
