defmodule Absinthe.Phase.Document.Arguments.FlagInvalid do
  @moduledoc """
  Marks arguments as bad if they have any invalid children.

  This is later used by the ArgumentsOfCorrectType phase.
  """

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @doc """
  Run this validation.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node/1)
    {:ok, result}
  end

  defp handle_node(%Blueprint.Input.Argument{input_value: input_value} = node) do
    node = if valid?(input_value) do
      node
    else
      node |> flag_invalid(:bad_argument)
    end

    {:halt, node}
  end
  defp handle_node(node) do
    node
  end

  defp valid?(node) do
    {_, result} = Blueprint.prewalk(node, true, &check_child/2)
    result
  end

  defp check_child(%{flags: %{invalid: _}} = node, _) do
    {:halt, node, false}
  end
  defp check_child(node, acc), do: {node, acc}
end
