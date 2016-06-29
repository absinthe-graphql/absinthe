defmodule Absinthe.IR.VariableDefinition do
  alias Absinthe.IR

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
    type: IR.NamedType.maybe_wrapped_t,
    errors: [IR.Error.t],
    default_value: IR.Input.t,
    ast_node: Absinthe.Language.t,
    schema_type: Absinthe.Type.t
  }

  def from_ast(node, doc) do
    
  end
end
