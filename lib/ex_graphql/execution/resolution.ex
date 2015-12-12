defprotocol ExGraphQL.Execution.Resolution do

  alias ExGraphQL.Language
  alias ExGraphQL.Type

  @type t :: %{target: any, parent_type: Type.t, type: Type.t, ast_node: Language.t}
  defstruct target: nil, parent_type: nil, type: nil, ast_node: nil

  @doc "Returns `true` if `data` is considered blank/empty"
  @spec resolve(ExGraphQL.Language.t, ExGraphQL.Execution.Resolution.t, ExGraphQL.Execution.t) :: {:ok, any} | {:error, any}
  def resolve(ast_node, resolution, execution)

end
