defprotocol Absinthe.Traversal.Node do

  @fallback_to_any true

  @spec children(any, Absinthe.Traversal.t) :: [any]
  def children(node, traversal)

end

defimpl Absinthe.Traversal.Node, for: Any do
  def children(node, _traversal), do: []
end
