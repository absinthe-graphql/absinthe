defmodule Absinthe.IR.IDL.Object do

  alias Absinthe.Language

  defstruct name: nil, errors: [], ast_node: nil
  @type t :: %__MODULE__{} # TODO

  def from_ast(%Language.ObjectDefinition{} = node) do
    %__MODULE__{name: node.name, ast_node: node}
  end

end
