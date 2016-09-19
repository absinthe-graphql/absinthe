defmodule Absinthe.Phase.Document.Validation.Result do

  @moduledoc """
  Collects validation errors into the result.
  """

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t, nil | Phase.t) :: Phase.result_t
  def run(input, abort_phase) do
    {input, errors} = Blueprint.prewalk(input, [], &handle_node/2)
    result = put_in(input.result.validation, errors)
    case {errors, abort_phase} do
      {[], _} ->
        {:ok, result}
      {_, nil} ->
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
