defmodule Absinthe.Phase.Document.Directives do
  @moduledoc false

  # Expand all directives in the document.
  #
  # Note that no validation occurs in this phase.

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &handle_node/1)
    {:ok, node}
  end

  @spec handle_node(Blueprint.node_t()) :: Blueprint.node_t()
  defp handle_node(%{directives: directives} = node) do
    Enum.reduce(directives, node, fn directive, acc ->
      Blueprint.Directive.expand(directive, acc)
    end)
  end

  defp handle_node(node) do
    node
  end
end
