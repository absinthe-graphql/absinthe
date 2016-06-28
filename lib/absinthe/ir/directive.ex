defmodule Absinthe.IR.Directive do

  defstruct name: nil, arguments: []
  @type t :: %__MODULE__{} # TODO

  def from_ast(node) do
    %__MODULE__{name: node.name} # TODO: Arguments
  end

end
