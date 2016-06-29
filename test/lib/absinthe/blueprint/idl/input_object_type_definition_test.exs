defmodule Absinthe.Blueprint.IDL.InputObjectTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  describe ".from_ast" do

    it "works, given an IDL 'input' definition" do
      assert %Blueprint.IDL.InputObjectTypeDefinition{name: "Profile"} = from_input("input Profile { name: String! }")
    end

    it "works, given an IDL 'input' definition and a directive" do
      rep = """
      input Profile
      @description(text: "A person's profile")
      {
        name: String!
      }
      """ |> from_input
      assert %Blueprint.IDL.InputObjectTypeDefinition{name: "Profile", directives: [%{name: "description"}], fields: [%Blueprint.IDL.InputValueDefinition{type: %Blueprint.NonNullType{of_type: %Blueprint.NamedType{name: "String"}}}]} = rep
    end

  end

  defp from_input(text) do
    doc = Absinthe.parse!(text)

    doc
    |> extract_ast_node
    |> Blueprint.IDL.InputObjectTypeDefinition.from_ast(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node
  end

end
