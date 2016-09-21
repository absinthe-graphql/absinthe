defmodule Absinthe.Phase.Validation.KnownTypeNamesTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Validation.KnownTypeNames

  use Support.Harness.Validation
  alias Absinthe.Blueprint

  def unknown_type(:variable_definition, name, line) do
    bad_value(
      Blueprint.Document.VariableDefinition,
      error_message(name),
      line,
      &(Blueprint.TypeReference.unwrap(&1.type).name == name)
    )
  end
  def unknown_type(:named_type_condition, name, line) do
    unknown_type_condition(Blueprint.Document.Fragment.Named, name, line)
  end
  def unknown_type(:spread_type_condition, name, line) do
    unknown_type_condition(Blueprint.Document.Fragment.Spread, name, line)
  end
  def unknown_type(:inline_type_condition, name, line) do
    unknown_type_condition(Blueprint.Document.Fragment.Inline, name, line)
  end

  def unknown_type_condition(node_type, name, line) do
    bad_value(
      node_type,
      error_message(name),
      line,
      &(&1.type_condition && Blueprint.TypeReference.unwrap(&1.type_condition).name == name)
    )
  end

  def error_message(type) do
    ~s(Unknown type "#{type}".)
  end

  describe "Validate: Known type names" do

    it "known type names are valid" do
      assert_passes_rule(@rule,
        """
        query Foo($var: String, $required: [String!]!) {
          user(id: 4) {
            pets { ... on Pet { name }, ...PetFields, ... { name } }
          }
        }
        fragment PetFields on Pet {
          name
        }
        """,
        []
      )
    end

    it "unknown type names are invalid" do
      assert_fails_rule(@rule,
        """
        query Foo($var: JumbledUpLetters) {
          user(id: 4) {
            name
            pets { ... on Badger { name }, ...PetFields }
          }
        }
        fragment PetFields on Peettt {
          name
        }
        """,
        [],
        [
         unknown_type(:variable_definition, "JumbledUpLetters", 1),
         unknown_type(:inline_type_condition, "Badger", 4),
         unknown_type(:named_type_condition, "Peettt", 7)
        ]
      )
    end

    it "ignores type definitions" do
      assert_fails_rule(@rule,
        """
        type NotInTheSchema {
          field: FooBar
        }
        interface FooBar {
          field: NotInTheSchema
        }
        union U = A | B
        input Blob {
          field: UnknownType
        }
        query Foo($var: NotInTheSchema) {
          user(id: $var) {
            id
          }
        }
        """,
        [],
        unknown_type(:variable_definition, "NotInTheSchema", 11)
      )
    end

  end

end
