defmodule Absinthe.Phase.Document.Validation.SelectedCurrentOperation do
  @moduledoc """
  Validates an operation name was provided when needed.
  """

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, _options \\ []) do
    node = if Enum.count(input.operations, &(&1.current)) == 1 do
      input
    else
      input
      |> flag_invalid(:no_current_operation)
      |> put_error(error)
    end
    {:ok, node}
  end

  # Generate the error
  @spec error :: Phase.Error.t
  defp error do
    Phase.Error.new(
      __MODULE__,
      error_message
    )
  end

  def error_message do
    ~s(Must provide a valid operation name if query contains multiple operations.)
  end

end
