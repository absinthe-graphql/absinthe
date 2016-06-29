defmodule Absinthe.IR.IDL.InterfaceTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.IR

  @text "An Entity"
  @idl """
  interface Entity
  @description(text: "#{@text}")
  {
    name: String!
  }
  type Person implements Entity {
    name: String!
  }
  type Business implements Entity {
    name: String!
  }
  """

  describe ".from_ast" do

    it "works, given an IDL 'interface' definition" do
      assert %IR.IDL.InterfaceTypeDefinition{name: "Entity", directives: [%{name: "description"}]} = from_input(@idl)
    end

  end

  defp from_input(text) do
    doc = Absinthe.parse!(text)

    doc
    |> extract_ast_node
    |> IR.IDL.InterfaceTypeDefinition.from_ast(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: definitions}) do
    definitions |> List.first
  end

end
