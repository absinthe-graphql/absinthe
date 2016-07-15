defmodule Absinthe.Phase.Document.Directives do
  @moduledoc """
  Expand all directives in the document.

  Note that no validation occurs in this phase.
  """

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t, any) :: {:ok, Blueprint.t}
  def run(input, _) do
    {node, _} = Blueprint.prewalk(input, %{}, &handle_node/2)
    {:ok, node}
  end

  @spec handle_node(Blueprint.node_t, map) :: {Blueprint.node_t, map}
  defp handle_node(%{directives: directives} = node, acc) do
    directives
    |> Enum.reduce({node, acc}, fn
      directive, {node, acc} ->
        Blueprint.Directive.expand(directive, node, acc)
    end)
  end
  defp handle_node(node, acc) do
    {node, acc}
  end

end
