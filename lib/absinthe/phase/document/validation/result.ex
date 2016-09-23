defmodule Absinthe.Phase.Document.Validation.Result do

  @moduledoc """
  Collects validation errors into the result.
  """

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
    {input, errors} = Blueprint.prewalk(input, [], &handle_node/2)
    result = put_in(input.result.validation, errors)
    case {errors, jump} do
      {[], _} ->
        {:ok, result}
      {_, false} ->
        {:ok, result}
      _ ->
        {:jump, result, abort_phase}
    end
  end

  # Collect the validation errors from nodes
  @spec handle_node(Blueprint.node_t, [Phase.Error.t]) :: {Blueprint.node_t, [Phase.Error.t]}
  defp handle_node(%{errors: errs} = node, acc) do
    {node, acc ++ errs}
  end
  defp handle_node(node, acc) do
    {node, acc}
  end

end
