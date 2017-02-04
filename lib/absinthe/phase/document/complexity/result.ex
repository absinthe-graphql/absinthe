defmodule Absinthe.Phase.Document.Complexity.Result do
  @moduledoc false

  # Collects validation errors into the result.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, options \\ []) do
    case Blueprint.current_operation(input) do
      %{flags: %{invalid: Phase.Document.Complexity.Analysis}} ->
        Phase.Document.Validation.Result.run(input, options)
      _ ->
        {:ok, input}
    end
  end
end
