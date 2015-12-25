defmodule Absinthe.Traversal do

  alias Absinthe.Traversal.Node

  def reduce(root, schema, initial_value, reducer) do
    case reducer.(root, schema, initial_value) do
      {:ok, value} ->
        reduce_children(root, schema, value, reducer)
      {:prune, result} ->
        result
      {:error, _} = err ->
        err
    end
  end

  defp reduce_children(root, schema, initial, reducer) do
    Enum.reduce(Node.children(root, schema), initial, fn
      child, acc ->
        reduce(child, schema, acc, reducer)
    end)
  end

end
