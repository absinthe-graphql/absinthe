defmodule Absinthe.Blueprint.Input.Argument do

  alias Absinthe.{Blueprint, Language}

  defstruct [
    name: nil,
    value: nil,
    errors: [],
    ast_node: nil,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Blueprint.Input.t,
    errors: [Blueprint.Error.t],
    ast_node: Language.t,
  }

  def from_ast(_node, _doc) do

  end

end
