defmodule Absinthe.IR.VariableDefinition do
  defstruct [
    name: nil,
    type: nil,
    errors: [],
    default_value: nil,
    ast_node: nil,
    schema_type: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    type: Absinthe.IR.Input.t,
    errors: [Absinthe.IR.Error.t],
    default_value: Absinthe.IR.Input.t,
    ast_node: Absinthe.Language.t,
    schema_type: Absinthe.Type.t
  }
end
