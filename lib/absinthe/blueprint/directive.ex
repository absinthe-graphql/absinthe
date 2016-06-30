defmodule Absinthe.Blueprint.Directive do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name]
  defstruct [
    :name,
    arguments: [],
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    arguments: [Absinthe.Blueprint.Input.Argument.t],
    errors: [Absinthe.Blueprint.Error.t],
    ast_node: nil | Language.Directive.t,
  }

  @spec from_ast(Language.Directive.t, Language.Document.t) :: t
  def from_ast(%Language.Directive{} = node, doc) do
    %__MODULE__{
      name: node.name,
      arguments: Enum.map(node.arguments, &Blueprint.Input.Argument.from_ast(&1, doc)),
      ast_node: node
    }
  end

end
