defmodule Absinthe.IR.NamedType do
  defstruct [
    name: nil,
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    ast_node: Absinthe.Language.NamedType.t,
  }

  @type maybe_wrapped_t :: IR.NonNull.t | IR.ListType.t | __MODULE__.t

  def from_ast(%{name: name} = node, _doc) do
    %__MODULE__{
      name: name,
      ast_node: node
    }
  end
end
