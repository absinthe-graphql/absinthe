defmodule Absinthe.Blueprint.Input.Argument do
  alias Absinthe.Blueprint

  defstruct [
    name: nil,
    value: nil,
    errors: [],
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Absinthe.Blueprint.Input.t,
    errors: [Absinthe.Blueprint.Error.t],
    ast_node: Absinthe.Language.t,
  }

  def from_ast(node, doc) do

  end
end
