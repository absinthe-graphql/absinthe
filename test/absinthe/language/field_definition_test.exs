defmodule Absinthe.Language.FieldDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  @idl """
  type Foo {
    bar: [String!]!
    baz @description(text: "A directive on baz"): Int
    quuxes(limit: Int = 4): [Quux]
  }
  """

  describe "converting to Blueprint" do
    test "works, given a Blueprint Schema object field definition" do
      {doc, fields} = fields_from_input(@idl)
      field_def = fields |> List.first() |> Blueprint.Draft.convert(doc)

      assert %Blueprint.Schema.FieldDefinition{
               name: "bar",
               type: %Blueprint.TypeReference.NonNull{
                 of_type: %Blueprint.TypeReference.List{
                   of_type: %Blueprint.TypeReference.NonNull{
                     of_type: %Blueprint.TypeReference.Name{name: "String"}
                   }
                 }
               }
             } = field_def
    end

    test "captures directives" do
      {doc, fields} = fields_from_input(@idl)
      field_def = fields |> Enum.at(1) |> Blueprint.Draft.convert(doc)
      assert %Blueprint.Schema.FieldDefinition{name: "baz"} = field_def
    end

    test "includes argument definitions" do
      {doc, fields} = fields_from_input(@idl)
      field_def = fields |> Enum.at(2) |> Blueprint.Draft.convert(doc)

      assert %Blueprint.Schema.FieldDefinition{
               identifier: :quuxes,
               name: "quuxes",
               type: %Blueprint.TypeReference.List{
                 of_type: %Blueprint.TypeReference.Name{name: "Quux"}
               },
               arguments: [
                 %Blueprint.Schema.InputValueDefinition{
                   name: "limit",
                   identifier: :limit,
                   type: %Blueprint.TypeReference.Name{name: "Int"},
                   default_value: 4,
                   default_value_blueprint: %Absinthe.Blueprint.Input.Integer{
                     errors: [],
                     flags: %{},
                     schema_node: nil,
                     source_location: %Absinthe.Blueprint.SourceLocation{column: 23, line: 4},
                     value: 4
                   },
                   source_location: %Absinthe.Blueprint.SourceLocation{column: 10, line: 4}
                 }
               ],
               source_location: %Absinthe.Blueprint.SourceLocation{column: 3, line: 4}
             } == field_def
    end
  end

  defp fields_from_input(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_fields
  end

  defp extract_fields(%Absinthe.Language.Document{definitions: definitions} = doc) do
    fields =
      definitions
      |> List.first()
      |> Map.get(:fields)

    {doc, fields}
  end
end
