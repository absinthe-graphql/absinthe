defmodule Absinthe.Blueprint.Directive do

  alias Absinthe.Language

  defstruct [
    name: nil,
    arguments: [],
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: String.t,
    arguments: [Absinthe.Blueprint.Argument.t],
    errors: [Absinthe.Blueprint.Error.t],
    ast_node: Language.t,
  }

  def from_ast(%Language.Directive{} = node, _doc) do
    %__MODULE__{
      name: node.name
    }
  end

end
