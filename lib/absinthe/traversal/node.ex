defprotocol Absinthe.Traversal.Node do
  @moduledoc false

  @fallback_to_any true

  @spec children(any, Absinthe.Traversal.t()) :: [any]
  def children(node, traversal)
end

defimpl Absinthe.Traversal.Node, for: Any do
  def children(_node, _traversal), do: []
end

defimpl Absinthe.Traversal.Node, for: Atom do
  def children(node, %{context: schema}) do
    if node == schema do
      # Root schema node
      [node.query, node.mutation, node.subscription]
      |> Enum.reject(&is_nil/1)
    else
      # Type Reference
      case Absinthe.Schema.lookup_type(schema, node) do
        nil ->
          []

        type ->
          [type]
      end
    end
  end

  def children(_node, _traversal) do
    []
  end
end
