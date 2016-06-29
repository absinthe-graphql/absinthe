defmodule Absinthe.Blueprint.IDL.DirectiveDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  describe ".from_ast" do

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
    doc = Absinthe.parse!(text)

    doc
    |> extract_ast_node
    |> Blueprint.IDL.DirectiveDefinition.from_ast(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node
  end

end
