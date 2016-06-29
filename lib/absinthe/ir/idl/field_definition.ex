defmodule Absinthe.IR.IDL.FieldDefinition do

  alias Absinthe.{IR, Language}

  defstruct [
    name: nil,
    type: nil
  ]

  @type t :: %__MODULE__{

  } # TODO

  def from_ast(node, _doc) do
    %__MODULE__{
      name: node.name,
      type: IR.type_from_ast_type(node.type)
    }
  end

end
