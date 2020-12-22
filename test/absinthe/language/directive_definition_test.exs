defmodule Absinthe.Language.DirectiveDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Language}

  describe "blueprint conversion" do
    test "works, given a Blueprint Schema 'directive' definition without arguments" do
      assert %Blueprint.Schema.DirectiveDefinition{
               name: "thingy",
               locations: [:field, :object],
               repeatable: false
             } = from_input("directive @thingy on FIELD | OBJECT")
    end

    test "works, given a Blueprint Schema 'repeatable' 'directive' definition without arguments" do
      assert %Blueprint.Schema.DirectiveDefinition{
               name: "thingy",
               locations: [:field, :object],
               repeatable: true
             } = from_input("directive @thingy repeatable on FIELD | OBJECT")
    end

    test "works, given a Blueprint Schema 'directive' definition without arguments and with directives" do
      rep =
        """
        directive @authorized(if: Boolean!) on FIELD @description(text: "When 'if' is true, only include the field if authorized")
        """
        |> from_input

      assert %Blueprint.Schema.DirectiveDefinition{
               name: "authorized",
               locations: [:field],
               directives: [%{name: "description"}]
             } = rep
    end
  end

  defp from_input(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Language.Document{definitions: [node]}) do
    node
  end
end
