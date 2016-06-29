defmodule Absinthe.IR.NonNullType do
  defstruct [
    of_type: nil,
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    of_type: __MODULE__.t | Absinthe.IR.List.t | Absinthe.IR.NamedType.t | Absinthe.IR.Input.t,
    ast_node: Absinthe.Language.NonNullType.t,
  }
end
