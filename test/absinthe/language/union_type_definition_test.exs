defmodule Absinthe.Language.UnionTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  @text "A metasyntactic variable"
  @idl """
  type Foo {
    name: String
  }

  type Bar {
    name: String
  }

  union Baz @description(text: "#{@text}") =
    Foo
  | Bar

  """

  describe "converting to Blueprint" do
    test "works, given a Blueprint Schema 'union' definition" do
      assert %Blueprint.Schema.UnionTypeDefinition{
               name: "Baz",
               types: [
                 %Blueprint.TypeReference.Name{name: "Foo"},
                 %Blueprint.TypeReference.Name{name: "Bar"}
               ],
               directives: [%{name: "description"}]
             } = from_input(@idl)
    end
  end

  defp from_input(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: definitions}) do
    definitions |> List.last()
  end
end
