defmodule Absinthe.Blueprint.Input.List do
  defstruct [
    values: [],
    ast_node: nil,
  ]
  @type t :: %__MODULE__{
    values: [Absinthe.Blueprint.Input.t]
  }
end
