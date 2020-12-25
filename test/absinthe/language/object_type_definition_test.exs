defmodule Absinthe.Language.ObjectTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  describe "converting to Blueprint" do
    test "works, given a Blueprint Schema 'type' definition" do
      assert %Blueprint.Schema.ObjectTypeDefinition{name: "Person"} =
               from_input("type Person { name: String! }")
    end

    test "works, given a Blueprint Schema 'type' definition and a built in directive" do
      rep =
        """
        type Person
        @description(text: "A person")
        {
          name: String!
        }
        """
        |> from_input

      assert %Blueprint.Schema.ObjectTypeDefinition{
               name: "Person",
               directives: [%{name: "description"}]
             } = rep
    end

    test "works, given a Blueprint Schema 'type' definition and a Type System directive" do
      rep =
        """
        type Person
        @typeSystemDirective(foo: "Bar")
        {
          name: String!
        }
        """
        |> from_input

      assert %Blueprint.Schema.ObjectTypeDefinition{
               name: "Person",
               directives: [%{name: "typeSystemDirective"}]
             } = rep
    end

    test "works, given a Blueprint Schema 'type' definition that implements an interface" do
      rep =
        """
        type Person implements Entity {
          name: String!
        }
        """
        |> from_input

      assert %Blueprint.Schema.ObjectTypeDefinition{
               name: "Person",
               interfaces: [:entity],
               interface_blueprints: [%Blueprint.TypeReference.Name{name: "Entity"}]
             } = rep
    end

    test "works, given a Blueprint Schema 'type' definition that implements an interface and uses a directive" do
      rep =
        """
        type Person implements Entity
        @description(text: "A person entity")
        {
          name: String!
        }
        """
        |> from_input

      assert %Blueprint.Schema.ObjectTypeDefinition{
               name: "Person",
               interfaces: [:entity],
               interface_blueprints: [%Blueprint.TypeReference.Name{name: "Entity"}],
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

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node
  end
end
