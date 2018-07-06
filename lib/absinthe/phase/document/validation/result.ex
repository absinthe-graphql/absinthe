defmodule Absinthe.Phase.Document.Validation.Result do
  @moduledoc false

  # Collects validation errors into the result.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, options \\ []) do
    do_run(input, Map.new(options))
  end

  @spec do_run(Blueprint.t(), %{result_phase: Phase.t(), jump_phases: boolean}) ::
          Phase.result_t()
  def do_run(input, %{result_phase: abort_phase, jump_phases: jump}) do
    {input, errors} = Blueprint.prewalk(input, [], &handle_node/2)
    errors = :lists.reverse(errors)
    result = put_in(input.execution.validation_errors, errors)

    case {errors, jump} do
      {[], _} ->
        {:ok, result}

      {_, false} ->
        {:error, result}

      _ ->
        {:jump, result, abort_phase}
    end
  end

  # Collect the validation errors from nodes
  @spec handle_node(Blueprint.node_t(), [Phase.Error.t()]) ::
          {Blueprint.node_t(), [Phase.Error.t()]}
  defp handle_node(%{errors: errs} = node, errors) do
    {node, :lists.reverse(errs) ++ errors}
  end

  defp handle_node(%{raw: raw} = node, errors) do
    {_, errors} = Blueprint.prewalk(raw, errors, &handle_node/2)
    {node, errors}
  end

  defp handle_node(node, acc), do: {node, acc}
end
