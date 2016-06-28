defmodule Absinthe.IR.Directive do

  alias Absinthe.Language

  defstruct name: nil, arguments: [], errors: [], ast_node: nil
  @type t :: %__MODULE__{
    name: String.t,
    arguments: [Absinthe.IR.Argument.t],
    errors: [Absinthe.IR.Error.t],
    ast_node: Language.t,
  }

  def from_ast(_) do
  end

end
