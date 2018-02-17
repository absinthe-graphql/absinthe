defmodule Absinthe.Phase.Document.Validation.Result do
  @moduledoc false

  # Collects validation errors into the result.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, options \\ []) do
    do_run(input, Map.new(options))
  end

  @spec do_run(Blueprint.t, %{result_phase: Phase.t, jump_phases: boolean}) :: Phase.result_t
  def do_run(input, %{result_phase: abort_phase, jump_phases: jump}) do
    {input, {errors, invalid}} = Blueprint.prewalk(input, {[], false}, &handle_node/2)
    result = put_in(input.execution.validation_errors, errors)
    case {errors, invalid, jump} do
      {[], false, _} ->
        {:ok, result}
      {_, _, false} ->
        {:error, result}
      _ ->
        {:jump, result, abort_phase}
    end
  end

  # Collect the validation errors from nodes
  @spec handle_node(Blueprint.node_t, [Phase.Error.t]) :: {Blueprint.node_t, [Phase.Error.t]}
  defp handle_node(node, acc) do
    check_errors(node, acc)
  end

  defp check_errors(%{errors: errs} = node, {errors, invalid}) do
    {node, {errors ++ errs, invalid}}
  end
  defp check_errors(node, acc), do: {node, acc}

end
