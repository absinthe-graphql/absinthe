defmodule Absinthe.Phase.Document.Validation.OnlyOneSubscription do
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
    bp =
      Blueprint.update_current(input, fn
        %{type: :subscription} = op ->
          check_op(op)

        op ->
          op
      end)

    {:ok, bp}
  end

  defp check_op(%{selections: [_, _ | _]} = op) do
    error = %Phase.Error{
      phase: __MODULE__,
      message: "Only one field is permitted on the root object when subscribing",
      locations: [op.source_location]
    }

    op
    |> flag_invalid(:too_many_fields)
    |> put_error(error)
  end

  defp check_op(op), do: op
end
