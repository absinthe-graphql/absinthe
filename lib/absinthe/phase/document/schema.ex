defmodule Absinthe.Phase.Document.Schema do
  use Absinthe.Phase

  alias Absinthe.Blueprint

  @spec run(Blueprint.t, Absinthe.Schema.t) :: {:ok, Blueprint.t}
  def run(input, schema) do
    {result, _} = Blueprint.prewalk(input, %{}, &handle_node(&1, schema, &2))
    {:ok, result}
  end

  @spec handle_node(Blueprint.node_t, Absinthe.Schema.t, map) :: Blueprint.node_t
  defp handle_node(%Blueprint{} = node, schema, acc) do
    {put_in(node.schema, schema), acc}
  end
  defp handle_node(%Blueprint.Directive{name: name} = node, schema, acc) do
    {
      put_in(node.schema_node, schema.__absinthe_directive__(name)),
      acc
    }
  end
  defp handle_node(node, _, acc) do
    {node, acc}
  end

end
