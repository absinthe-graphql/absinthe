defmodule Absinthe.Language.EnumTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  describe "converting to Blueprint" do

    it "works, given an IDL 'enum' definition" do
      rep = "enum Episode { NEWHOPE, EMPIRE, JEDI }" |> from_input
      assert %Blueprint.IDL.EnumTypeDefinition{name: "Episode", values: ["NEWHOPE", "EMPIRE", "JEDI"]} = rep
    end

    it "works, given an IDL 'enum' definition with a directive" do
      rep = """
      enum Episode @description(text: "An episode") { NEWHOPE, EMPIRE, JEDI }
      """ |> from_input
      assert %Blueprint.IDL.EnumTypeDefinition{name: "Episode", directives: [%Blueprint.Directive{name: "description"}], values: ["NEWHOPE", "EMPIRE", "JEDI"]} = rep
    end


  end

  defp from_input(text) do
    {:ok, doc} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node
  end

end
