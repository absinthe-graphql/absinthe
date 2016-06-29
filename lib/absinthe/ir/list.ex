defmodule Absinthe.IR.List do
  defstruct [
    of_type: nil,
    ast_node: nil,
  ]
  @type t :: %__MODULE__{
    of_type: __MODULE__.t | Absinthe.IR.NonNull.t | Absinthe.IR.NamedType.t | Absinthe.IR.Input.t
  }
end
