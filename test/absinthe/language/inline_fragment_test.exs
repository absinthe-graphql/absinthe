defmodule Absinthe.Language.InlineFragmentTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Language}

  @query """
  {
    ... on RootQueryType {
      foo
      bar
    }
  }
  """

  describe "converting to Blueprint" do
    test "builds a Document.Fragment.Inline.t" do
      assert %Blueprint.Document.Fragment.Inline{
               type_condition: %Blueprint.TypeReference.Name{name: "RootQueryType"},
               selections: [
                 %Blueprint.Document.Field{name: "foo"},
                 %Blueprint.Document.Field{name: "bar"}
               ]
             } = from_input(@query)
    end
  end

  defp from_input(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Language.Document{definitions: nodes}) do
    op =
      nodes
      |> List.first()

    op.selection_set.selections
    |> List.first()
  end
end
