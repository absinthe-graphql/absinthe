defmodule Absinthe.Phase.Document.Arguments.FlagInvalid do
  @moduledoc false

  # Marks arguments as bad if they have any invalid children.
  #
  # This is later used by the ArgumentsOfCorrectType phase.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @doc """
  Run this validation.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, _options \\ []) do
    result = Blueprint.postwalk(input, &handle_node/1)
    {:ok, result}
  end

  defp handle_node(%{schema_node: nil, flags: %{}} = node) do
    node |> flag_invalid(:extra)
  end
  defp handle_node(%Blueprint.Input.Argument{} = node) do
    check_children(node, node.input_value.normalized, :bad_argument)
  end
  defp handle_node(%Blueprint.Input.Field{} = node) do
    check_children(node, node.input_value.normalized, :bad_field)
  end
  defp handle_node(%Blueprint.Input.List{} = node) do
    check_children(node, node.items |> Enum.map(&(&1.normalized)), :bad_list)
  end
  defp handle_node(%Blueprint.Input.Object{} = node) do
    check_children(node, node.fields, :bad_object)
  end
  defp handle_node(node), do: node

  defp check_children(node, children, flag) do
    children
    |> Blueprint.prewalk(true, fn
      %{flags: %{invalid: _}} = child, _ ->
        {:halt, child, false}
      node, acc ->
        {:halt, node, acc}
    end)
    |> case do
      {_, true} -> node
      {_, false} -> node |> flag_invalid(flag)
    end
  end
end
