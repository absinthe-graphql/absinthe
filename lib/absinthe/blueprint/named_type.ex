defmodule Absinthe.Blueprint.NamedType do
  defstruct [
    name: nil,
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    ast_node: Absinthe.Language.NamedType.t,
  }

  @type maybe_wrapped_t :: Blueprint.NonNull.t | Blueprint.ListType.t | __MODULE__.t

  def from_ast(%{name: name} = node, _doc) do
    %__MODULE__{
      name: name,
      ast_node: node
    }
  end
end
