defprotocol Absinthe.Traversal.Node do

  @fallback_to_any true

  @spec children(any, Absinthe.Schema.t) :: [any]
  def children(node, schema)

end

defimpl Absinthe.Traversal.Node, for: Any do
  def children(_node, _schema), do: []
end
