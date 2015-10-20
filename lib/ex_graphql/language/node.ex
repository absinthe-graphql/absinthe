defprotocol ExGraphQL.Language.Node do

  @fallback_to_any true

  @spec children(ExGraphQL.Language.Node.t) :: [ExGraphQL.Language.Node.t]
  def children(node)

end

defimpl ExGraphQL.Language.Node, for: Any do
  def children(node), do: []
end
