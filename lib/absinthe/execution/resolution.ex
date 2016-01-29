defprotocol Absinthe.Execution.Resolution do

  @moduledoc false

  alias Absinthe.Language
  alias Absinthe.Type

  @type t :: %{target: any, parent_type: Type.t, type: Type.t, ast_node: Language.t}
  defstruct target: nil, parent_type: nil, type: nil, ast_node: nil

  @spec resolve(Absinthe.Language.t, Absinthe.Execution.t) :: {:ok, any, Absinthe.Execution.t} | {:error, any}
  def resolve(ast_node, execution)

end
