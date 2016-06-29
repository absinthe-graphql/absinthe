defmodule Absinthe.IR.IDL.InputObjectTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.IR

  describe ".from_ast" do

    it "works, given an IDL 'input' definition" do
      assert %IR.IDL.InputObjectTypeDefinition{name: "Profile"} = from_input("input Profile { name: String! }")
    end

    it "works, given an IDL 'input' definition and a directive" do
      rep = """
      input Profile
      @description(text: "A person's profile")
      {
        name: String!
      }
      """ |> from_input
      assert %IR.IDL.InputObjectTypeDefinition{name: "Profile", directives: [%{name: "description"}], fields: [%IR.IDL.InputValueDefinition{type: %IR.NonNullType{of_type: %IR.NamedType{name: "String"}}}]} = rep
    end

  end

  defp from_input(text) do
    doc = Absinthe.parse!(text)

    doc
    |> extract_ast_node
    |> IR.IDL.InputObjectTypeDefinition.from_ast(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node
  end

end
