defmodule Absinthe.Blueprint.Input.Enum do
  defstruct [
    value: nil,
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    value: binary,
    ast_node: Absinthe.Language.t
  }
end
