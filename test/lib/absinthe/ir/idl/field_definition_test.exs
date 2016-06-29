defmodule Absinthe.IR.IDL.FieldDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.IR

  @idl """
  type Foo {
    bar: [String!]!
    baz @description(text: "A directive on baz"): Int
    quuxes(limit: Int = 4): [Quux]
  }
  """

  describe ".from_ast" do

    it "works, given an IDL object field definition" do
      {doc, fields} = fields_from_input(@idl)
      field_def = fields |> List.first |> IR.IDL.FieldDefinition.from_ast(doc)
      assert %IR.IDL.FieldDefinition{name: "bar", type: %IR.NonNullType{of_type: %IR.ListType{of_type: %IR.NonNullType{of_type: %IR.NamedType{name: "String"}}}}} = field_def
    end

    it "captures directives" do
      {doc, fields} = fields_from_input(@idl)
      field_def = fields |> Enum.at(1) |> IR.IDL.FieldDefinition.from_ast(doc)
      assert %IR.IDL.FieldDefinition{name: "baz"} = field_def
    end

    it "includes argument definitions" do
      {doc, fields} = fields_from_input(@idl)
      field_def = fields |> Enum.at(2) |> IR.IDL.FieldDefinition.from_ast(doc)
      assert %IR.IDL.FieldDefinition{name: "quuxes", type: %IR.ListType{of_type: %IR.NamedType{name: "Quux"}}, arguments: [%IR.IDL.ArgumentDefinition{name: "limit", type: %IR.NamedType{name: "Int"}, default_value: %IR.Input.Integer{value: 4}}]} = field_def
    end

  end

  defp fields_from_input(text) do
    doc = Absinthe.parse!(text)

    doc
    |> extract_fields
  end

  defp extract_fields(%Absinthe.Language.Document{definitions: definitions} = doc) do
    fields = definitions
    |> List.first
    |> Map.get(:fields)
    {doc, fields}
  end

end
