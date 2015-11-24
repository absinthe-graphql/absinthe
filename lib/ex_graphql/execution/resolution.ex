defprotocol ExGraphQL.Execution.Resolution do

  @doc "Returns `true` if `data` is considered blank/empty"
  @spec resolve(ExGraphQL.Language.t, any, ExGraphQL.Execution.t) :: {:ok, any} | {:error, any}
  def resolve(ast_node, target, execution)

end
