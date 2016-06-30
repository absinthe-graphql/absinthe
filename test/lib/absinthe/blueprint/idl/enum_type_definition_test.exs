defmodule Absinthe.Blueprint.IDL.EnumTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  describe ".from_ast" do

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
    doc = Absinthe.parse!(text)

    doc
    |> extract_ast_node
    |> Blueprint.IDL.EnumTypeDefinition.from_ast(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node
  end

end
