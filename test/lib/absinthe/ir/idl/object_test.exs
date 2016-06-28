defmodule Absinthe.IR.IDL.ObjectTest do
  use Absinthe.Case, async: true

  alias Absinthe.IR

  describe ".from_ast" do

    test "works, given an IDL 'type' definition" do
      assert %IR.IDL.Object{name: "Person"} = from_input("type Person { name: String! }")
    end

    test "works, given an IDL 'type' definition and a directive" do
      rep = """
      type Person
      @description(text: "A person")
      {
        name: String!
      }
      """ |> from_input
      assert %IR.IDL.Object{name: "Person", directives: [%{name: "description"}]} = rep
    end

    test "works, given an IDL 'type' definition that implements an interface" do
      rep = """
      type Person implements Entity {
        name: String!
      }
      """ |> from_input
      assert %IR.IDL.Object{name: "Person", interfaces: ["Entity"]} = rep
    end

    test "works, given an IDL 'type' definition that implements an interface and uses a directive" do
      rep = """
      type Person implements Entity
      @description(text: "A person entity")
      {
        name: String!
      }
      """ |> from_input
      assert %IR.IDL.Object{name: "Person", interfaces: ["Entity"], directives: [%{name: "description"}]} = rep
    end

  end

  defp from_input(text) do
    Absinthe.parse!(text)
    |> extract_ast_node
    |> IR.IDL.Object.from_ast
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node
  end

end
