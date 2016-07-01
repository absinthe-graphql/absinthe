defmodule Absinthe.Blueprint.Input.Object do

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:fields]
  defstruct [
    fields: [],
    ast_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    fields: [Blueprint.Input.Field.t],
    ast_node: nil | Language.ObjectValue.t,
    errors: [Absinthe.Phase.Error.t],
  }

  @spec from_ast(Language.ObjectValue.t, Language.Document.t) :: t
  def from_ast(%Language.ObjectValue{} = node, doc) do
    %__MODULE__{
      fields: Enum.map(node.fields, &Blueprint.Input.Field.from_ast(&1, doc)),
      ast_node: node
    }
  end

end
