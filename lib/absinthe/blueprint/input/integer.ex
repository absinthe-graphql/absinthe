defmodule Absinthe.Blueprint.Input.Integer do
  defstruct [
    value: nil,
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    value: integer,
    ast_node: Absinthe.Language.t
  }
end
