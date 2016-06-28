defmodule Absinthe.IR.Operation do

  alias Absinthe.Language

  defstruct name: nil, type: nil, errors: [], ast_node: nil
  @type t :: %__MODULE__{} # TODO

  def from_ast(%Language.OperationDefinition{} = node) do
    %__MODULE__{name: node.name, type: node.operation, ast_node: node}
  end

end
