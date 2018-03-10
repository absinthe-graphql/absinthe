defmodule Absinthe.Language.Field do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct alias: nil,
            name: nil,
            arguments: [],
            directives: [],
            selection_set: nil,
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          alias: nil | String.t(),
          name: String.t(),
          arguments: [Absinthe.Language.Argument.t()],
          directives: [Absinthe.Language.Directive.t()],
          selection_set: Absinthe.Language.SelectionSet.t(),
          loc: Absinthe.Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Document.Field{
        name: node.name,
        alias: node.alias,
        selections: Absinthe.Blueprint.Draft.convert(selections(node.selection_set), doc),
        arguments: Absinthe.Blueprint.Draft.convert(node.arguments, doc),
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc),
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)

    @spec selections(nil | Language.SelectionSet.t()) :: [
            Language.Field.t() | Language.InlineFragment.t() | Language.FragmentSpread.t()
          ]
    defp selections(nil), do: []
    defp selections(node), do: node.selections
  end

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.arguments, node.directives, node.selection_set |> List.wrap()]
      |> Enum.concat()
    end
  end
end
