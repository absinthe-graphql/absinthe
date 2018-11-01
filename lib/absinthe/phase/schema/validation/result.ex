defmodule Absinthe.Phase.Schema.Validation.Result do
  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _opts) do
    {input, errors} = Blueprint.prewalk(input, [], &handle_node/2)
    errors = errors |> :lists.reverse() |> Enum.uniq()

    case errors do
      [] ->
        {:ok, input}

      _ ->
        {:error, errors}
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
