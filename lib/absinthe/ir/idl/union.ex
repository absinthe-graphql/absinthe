defmodule Absinthe.IR.IDL.Union do

  alias Absinthe.Language

  defstruct name: nil, types: [], errors: [], ast_node: nil
  @type t :: %__MODULE__{} # TODO

  def from_ast(%Language.UnionTypeDefinition{} = node) do
    %__MODULE__{
      name: node.name,
      types: Enum.map(node.types, &(&1.name)),
      ast_node: node
    }
  end

end
