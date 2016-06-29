defmodule Absinthe.Blueprint.Input.Float do
  defstruct [
    value: nil,
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    value: float,
    ast_node: Absinthe.Language.t
  }
end
