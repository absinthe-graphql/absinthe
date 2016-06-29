defmodule Absinthe.IR.Directive do

  alias Absinthe.Language

  defstruct [
    name: nil,
    arguments: [],
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: String.t,
    arguments: [Absinthe.IR.Argument.t],
    errors: [Absinthe.IR.Error.t],
    ast_node: Language.t,
  }

<<<<<<< HEAD
  def from_ast(%Language.Directive{} = node) do
    %__MODULE__{
      name: node.name
    }
=======
  def from_ast(_node, _doc) do
>>>>>>> 69bd2bc... pass doc through
  end

end
