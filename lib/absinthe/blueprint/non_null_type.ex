defmodule Absinthe.Blueprint.NonNullType do
  defstruct [
    of_type: nil,
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    of_type: __MODULE__.t | Absinthe.Blueprint.List.t | Absinthe.Blueprint.NamedType.t | Absinthe.Blueprint.Input.t,
    ast_node: Absinthe.Language.NonNullType.t,
  }
end
