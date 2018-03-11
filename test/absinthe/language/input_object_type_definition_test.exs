defmodule Absinthe.Language.InputObjectTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  describe "converting to Blueprint" do
    test "works, given a Blueprint Schema 'input' definition" do
      assert %Blueprint.Schema.InputObjectTypeDefinition{name: "Profile"} =
               from_input("input Profile { name: String! }")
    end

    test "works, given a Blueprint Schema 'input' definition and a directive" do
      rep =
        """
        input Profile
        @description(text: "A person's profile")
        {
          name: String!
        }
        """
        |> from_input

      assert %Blueprint.Schema.InputObjectTypeDefinition{
               name: "Profile",
               directives: [%{name: "description"}],
               fields: [
                 %Blueprint.Schema.InputValueDefinition{
                   name: "name",
                   type: %Blueprint.TypeReference.NonNull{
                     of_type: %Blueprint.TypeReference.Name{name: "String"}
                   }
                 }
               ]
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
