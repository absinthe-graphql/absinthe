defprotocol ExGraphQL.Execution.Resolution do

  alias ExGraphQL.Type

  @type t :: %{target: Type.t, parent_type: Type.t, type: Type.t}
  defstruct target: nil, parent_type: nil, type: nil

  @doc "Returns `true` if `data` is considered blank/empty"
  @spec resolve(ExGraphQL.Language.t, ExGraphQL.Execution.Resolution, ExGraphQL.Execution.t) :: {:ok, any} | {:error, any}
  def resolve(ast_node, resolution, execution)

end
