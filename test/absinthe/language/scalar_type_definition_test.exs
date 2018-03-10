defmodule Absinthe.Language.ScalarTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  describe "converting to Blueprint" do
    test "works, given a Blueprint Schema 'scalar' definition" do
      assert %Blueprint.Schema.ScalarTypeDefinition{name: "Time"} = from_input("scalar Time")
    end

    test "works, given a Blueprint Schema 'scalar' definition with a directive" do
      rep =
        """
        scalar Time @description(text: "A datetime with a timezone")
        """
        |> from_input

      assert %Blueprint.Schema.ScalarTypeDefinition{
               name: "Time",
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
