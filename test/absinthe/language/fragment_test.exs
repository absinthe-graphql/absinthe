defmodule Absinthe.Language.FragmentTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Language}

  @query """
  fragment FooFields on Foo {
    foo
    bar
  }
  """

  describe "converting to Blueprint" do
    test "builds a Document.Fragment.Named.t" do
      assert %Blueprint.Document.Fragment.Named{
               name: "FooFields",
               type_condition: %Blueprint.TypeReference.Name{name: "Foo"},
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
    nodes
    |> List.first()
  end
end
