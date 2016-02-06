defprotocol Absinthe.Traversal.Node do

  @fallback_to_any true

  @spec children(any, Absinthe.Traversal.t) :: [any]
  def children(node, traversal)

end

defimpl Absinthe.Traversal.Node, for: Any do
  def children(_node, _traversal), do: []
end

defimpl Absinthe.Traversal.Node, for: Atom do
  # Type Reference
  def children(node, %{context: schema}) do
    case Absinthe.Schema.lookup_type(schema, node) do
      nil ->
        []
      type ->
        [type]
    end
  end
  def children(_node, _traversal) do
    []
  end
end
