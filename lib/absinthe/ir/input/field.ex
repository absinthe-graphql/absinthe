defmodule Absinthe.IR.Input.Field do
  defstruct [
    name: nil,
    type: nil,
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    type: Absinthe.IR.Input.t,
    ast_node: Absinthe.Language.t,
    errors: [Absinthe.IR.Error.t]
  }
end
