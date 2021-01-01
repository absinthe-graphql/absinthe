defmodule Absinthe.Phase.Schema.ReformatDescriptions do
  @moduledoc false

  # Trim all Descriptions

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &handle_node/1)
    {:ok, node}
  end

  @spec handle_node(Blueprint.node_t()) :: Blueprint.node_t()
  defp handle_node(%{description: description} = node)
       when is_binary(description) do
    %{node | description: String.trim(description)}
  end

  defp handle_node(node) do
    node
  end
end
