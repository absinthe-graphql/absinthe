defmodule Absinthe.Phase.Document.Arguments.CoerceLists do
  @moduledoc false

  # Coerce non-list inputs to lists when appropriate.
  #
  # IE
  # ```
  # foo(ids: 1)
  # ```
  # becomes
  # ```
  # foo(ids: [1])
  # ```
  #
  # if `ids` is a list type.

  use Absinthe.Phase
  alias Absinthe.{Blueprint, Type}
  alias Absinthe.Blueprint.Input

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &coerce_node/1)
    {:ok, node}
  end

  defp coerce_node(%Input.Value{normalized: nil} = node), do: node

  defp coerce_node(%Input.Value{normalized: %Input.Null{}} = node) do
    node
  end

  defp coerce_node(%Input.Value{} = node) do
    case Type.unwrap_non_null(node.schema_node) do
      %Type.List{} ->
        %{node | normalized: Input.List.wrap(node.normalized, node.schema_node)}

      _ ->
        node
    end
  end

  defp coerce_node(node), do: node
end
