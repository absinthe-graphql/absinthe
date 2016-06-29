defmodule Absinthe.IR.IDL.ArgumentDefinition do

  alias Absinthe.{IR, Language}

  defstruct [
    name: nil,
    default_value: nil,
    type: nil,
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: binary,
    default_value: any,
    type: IR.type_reference_t,
    errors: [IR.Error.t],
    ast_node: nil | Language.t
  }

  def from_ast(%Language.InputValueDefinition{} = node, doc) do
    %__MODULE__{
      name: node.name,
      default_value: ast_default_value(node.default_value, doc),
      type: IR.type_from_ast_type(node.type),
      ast_node: node
    }
  end

  @spec ast_default_value(nil | Language.input_t, Language.Document.t) :: nil | IR.Input.t
  defp ast_default_value(nil, _), do: nil
  defp ast_default_value(node, doc), do: IR.Input.from_ast(node, doc)

end
