defmodule Absinthe.Language.OperationDefinition do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    operation: nil,
    name: nil,
    variable_definitions: [],
    directives: [],
    selection_set: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    operation: :query | :mutation | :subscription,
    name: nil | binary,
    variable_definitions: [Language.VariableDefinition.t],
    selection_set: Language.SelectionSet.t,
    loc: Language.loc_t
  }

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.variable_definitions,
       node.directives,
       List.wrap(node.selection_set)]
      |> Enum.concat
    end
  end

end
