defprotocol ExGraphQL.Language.Node do

  @spec children(ExGraphQL.Language.Node.t) :: [ExGraphQL.Language.Node.t]
  def children(node)

end
