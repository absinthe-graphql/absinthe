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
  def run(input, _options \\ []) do
    result =
      case {Blueprint.current_operation(input), length(input.operations)} do
        {nil, count} when count > 1 ->
          input
          |> flag_invalid(:no_current_operation)
          |> put_error(error())

        _ ->
          input
      end

    {:ok, result}
  end

  # Generate the error
  @spec error :: Phase.Error.t()
  defp error do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message()
    }
  end

  def error_message do
    ~s(Must provide a valid operation name if query contains multiple operations.)
  end
end
