defprotocol Absinthe.Language.Node do

  @fallback_to_any true

  @spec children(Absinthe.Language.Node.t) :: [Absinthe.Language.Node.t]
  def children(node)

end

defimpl Absinthe.Language.Node, for: Any do
  def children(node), do: []
end
