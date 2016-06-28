defmodule Absinthe.IR.IDL.Enum do

  alias Absinthe.Language

  defstruct name: nil, values: [], errors: [], ast_node: nil
  @type t :: %__MODULE__{} # TODO

  def from_ast(%Language.EnumTypeDefinition{} = node) do
    %__MODULE__{
      name: node.name,
      values: node.values,
      ast_node: node
    }
  end

end
