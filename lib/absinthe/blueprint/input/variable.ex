defmodule Absinthe.Blueprint.Input.Variable do
  defstruct [
    name: nil,
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    ast_node: Absinthe.Language.t
  }
end
