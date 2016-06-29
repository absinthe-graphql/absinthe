defmodule Absinthe.Blueprint.Input.Object do

  defstruct [
    fields: [],
    errors: [],
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    fields: [Absinthe.Blueprint.Input.Field.t],
    errors: [Absinthe.Blueprint.Error.t],
    ast_node: Absinthe.Language.t
  }
end
