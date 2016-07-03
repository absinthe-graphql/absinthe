defmodule Absinthe.Language.DirectiveDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Language, Phase}

  describe "blueprint conversion" do

    it "works, given an IDL 'directive' definition without arguments" do
      assert %Blueprint.IDL.DirectiveDefinition{name: "thingy", locations: ["FIELD", "OBJECT"]} = from_input("directive @thingy on FIELD | OBJECT")
    end

    it "works, given an IDL 'directive' definition without arguments and with directives" do
      rep = """
      directive @authorized(if: Boolean!) on FIELD @description(text: "When 'if' is true, only include the field if authorized")
      """ |> from_input
      assert %Blueprint.IDL.DirectiveDefinition{name: "authorized", locations: ["FIELD"], directives: [%{name: "description"}]} = rep
    end

  end

  defp from_input(text) do
    {:ok, doc} = Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Language.Document{definitions: [node]}) do
    node
  end

end
