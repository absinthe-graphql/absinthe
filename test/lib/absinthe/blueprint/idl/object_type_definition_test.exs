defmodule Absinthe.Blueprint.IDL.ObjectTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  describe ".from_ast" do

    it "works, given an IDL 'type' definition" do
      assert %Blueprint.IDL.ObjectTypeDefinition{name: "Person"} = from_input("type Person { name: String! }")
    end

    it "works, given an IDL 'type' definition and a directive" do
      rep = """
      type Person
      @description(text: "A person")
      {
        name: String!
      }
      """ |> from_input
      assert %Blueprint.IDL.ObjectTypeDefinition{name: "Person", directives: [%{name: "description"}]} = rep
    end

    it "works, given an IDL 'type' definition that implements an interface" do
      rep = """
      type Person implements Entity {
        name: String!
      }
      """ |> from_input
      assert %Blueprint.IDL.ObjectTypeDefinition{name: "Person", interfaces: [%Blueprint.NamedType{name: "Entity"}]} = rep
    end

    it "works, given an IDL 'type' definition that implements an interface and uses a directive" do
      rep = """
      type Person implements Entity
      @description(text: "A person entity")
      {
        name: String!
      }
      """ |> from_input
      assert %Blueprint.IDL.ObjectTypeDefinition{name: "Person", interfaces: [%Blueprint.NamedType{name: "Entity"}], directives: [%{name: "description"}]} = rep
    end

  end

  defp from_input(text) do
    doc = Absinthe.parse!(text)

    doc
    |> extract_ast_node
    |> Blueprint.IDL.ObjectTypeDefinition.from_ast(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node
  end

end
