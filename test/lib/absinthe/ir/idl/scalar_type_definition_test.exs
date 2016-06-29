defmodule Absinthe.IR.IDL.ScalarTypeDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.IR

  describe ".from_ast" do

    it "works, given an IDL 'scalar' definition" do
      assert %IR.IDL.ScalarTypeDefinition{name: "Time"} = from_input("scalar Time")
    end

    it "works, given an IDL 'scalar' definition with a directive" do
      rep = """
      scalar Time @description(text: "A datetime with a timezone")
      """ |> from_input
      assert %IR.IDL.ScalarTypeDefinition{name: "Time", directives: [%{name: "description"}]} = rep
    end


  end

  defp from_input(text) do
    doc = Absinthe.parse!(text)

    doc
    |> extract_ast_node
    |> IR.IDL.ScalarTypeDefinition.from_ast(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node
  end

end
