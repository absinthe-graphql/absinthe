defmodule Absinthe.Language.InterfaceTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

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

  describe "converting to Blueprint" do
    test "works, given a Blueprint Schema 'interface' definition" do
      assert %Blueprint.Schema.InterfaceTypeDefinition{
               name: "Entity",
               directives: [%{name: "description"}]
             } = from_input(@idl)
    end
  end

  defp from_input(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: definitions}) do
    definitions |> List.first()
  end
end
