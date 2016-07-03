defmodule Absinthe.Language.OperationDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

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
    name: nil | String.t,
    variable_definitions: [Language.VariableDefinition.t],
    selection_set: Language.SelectionSet.t,
    loc: Language.loc_t
  }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Operation{
        name: node.name,
        type: node.operation,
        variable_definitions: Absinthe.Blueprint.Draft.convert(node.variable_definitions, doc),
        fields: Absinthe.Blueprint.Draft.convert(node.selection_set.selections, doc),
      }
    end
  end

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.variable_definitions,
       node.directives,
       List.wrap(node.selection_set)]
      |> Enum.concat
    end
  end

end
