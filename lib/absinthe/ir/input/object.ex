defmodule Absinthe.IR.Input.Object do

  defstruct [
    fields: [],
    errors: [],
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    fields: [Absinthe.IR.Input.Field.t],
    errors: [Absinthe.IR.Error.t],
    ast_node: Absinthe.Language.t
  }
end
