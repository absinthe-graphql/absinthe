defmodule Absinthe.IR.IDL.UnionDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.IR

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

  describe ".from_ast" do

    it "works, given an IDL 'union' definition" do
      assert %IR.IDL.UnionTypeDefinition{name: "Baz", types: ["Foo", "Bar"], directives: [%{name: "description"}]} = from_input(@idl)
    end

  end

  defp from_input(text) do
    Absinthe.parse!(text)
    |> extract_ast_node
    |> IR.IDL.UnionTypeDefinition.from_ast
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: definitions}) do
    definitions |> List.last
  end

end
