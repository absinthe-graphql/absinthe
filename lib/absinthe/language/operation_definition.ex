defmodule Absinthe.Language.OperationDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct operation: nil,
            name: nil,
            variable_definitions: [],
            directives: [],
            selection_set: nil,
            loc: %{line: nil}

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
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.SourceLocation.at(loc)
  end
end
