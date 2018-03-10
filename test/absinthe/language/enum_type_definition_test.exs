defmodule Absinthe.Language.EnumTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  describe "converting to Blueprint" do
    test "works, given a Blueprint Schema 'enum' definition" do
      rep = "enum Episode { NEWHOPE, EMPIRE, JEDI }" |> from_input

      assert %Blueprint.Schema.EnumTypeDefinition{
               name: "Episode",
               values: [
                 %Blueprint.Schema.EnumValueDefinition{value: "NEWHOPE"},
                 %Blueprint.Schema.EnumValueDefinition{value: "EMPIRE"},
                 %Blueprint.Schema.EnumValueDefinition{value: "JEDI"}
               ]
             } = rep
    end

    test "works, given a Blueprint Schema 'enum' definition with a directive" do
      rep =
        """
        enum Episode @description(text: "An episode") { NEWHOPE, EMPIRE, JEDI }
        """
        |> from_input

      assert %Blueprint.Schema.EnumTypeDefinition{
               name: "Episode",
               directives: [%Blueprint.Directive{name: "description"}],
               values: [
                 %Blueprint.Schema.EnumValueDefinition{value: "NEWHOPE"},
                 %Blueprint.Schema.EnumValueDefinition{value: "EMPIRE"},
                 %Blueprint.Schema.EnumValueDefinition{value: "JEDI"}
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
