defmodule Absinthe.IR.ListType do
  defstruct [
    of_type: nil,
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    of_type: __MODULE__.t | Absinthe.IR.NonNull.t | Absinthe.IR.NamedType.t,
    ast_node: Absinthe.Language.ListType.t
  }
end
