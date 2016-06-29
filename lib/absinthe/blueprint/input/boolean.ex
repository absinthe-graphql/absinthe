defmodule Absinthe.Blueprint.Input.Boolean do
  defstruct [
    value: nil,
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    value: true | false,
    ast_node: Absinthe.Language.t
  }
end
