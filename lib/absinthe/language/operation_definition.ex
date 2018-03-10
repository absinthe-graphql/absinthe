defmodule Absinthe.Language.OperationDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct operation: nil,
            name: nil,
            variable_definitions: [],
            directives: [],
            selection_set: nil,
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          operation: :query | :mutation | :subscription,
          name: nil | String.t(),
          variable_definitions: [Language.VariableDefinition.t()],
          directives: [Language.Directive.t()],
          selection_set: Language.SelectionSet.t(),
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Document.Operation{
        name: node.name,
        type: node.operation,
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc),
        variable_definitions: Blueprint.Draft.convert(node.variable_definitions, doc),
        selections: Blueprint.Draft.convert(node.selection_set.selections, doc),
        source_location: source_location(node.loc)
      }
    end

    defp source_location(nil) do
      nil
    end

    defp source_location(%{start_line: number}) do
      Blueprint.Document.SourceLocation.at(number)
    end
  end

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.variable_definitions, node.directives, List.wrap(node.selection_set)]
      |> Enum.concat()
    end
  end
end
