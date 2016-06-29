defmodule Absinthe.IR.Input.List do
  defstruct [
    values: [],
    ast_node: nil,
  ]
  @type t :: %__MODULE__{
    values: [Absinthe.IR.Input.t]
  }
end
