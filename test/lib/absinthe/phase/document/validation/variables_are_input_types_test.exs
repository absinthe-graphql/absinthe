defmodule Absinthe.Phase.Document.Validation.VariablesAreInputTypesTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.VariablesAreInputTypes

  use Support.Harness.Validation
  alias Absinthe.Blueprint

  defp non_input_type(name, type_rep, line) do
    bad_value(
      Blueprint.Document.VariableDefinition,
      @rule.error_message(name, type_rep),
      line,
      name: name
    )
  end

  context "Validate: Variables are input types" do

    it "input types are valid" do
      assert_passes_rule(@rule,
      """
        query Foo($a: String, $b: [Boolean!]!, $c: ComplexInput) {
          field(a: $a, b: $b, c: $c)
        }
      """,
      []
    )
    end

    it "output types are invalid" do
      assert_fails_rule(@rule,
        """
        query Foo($a: Dog, $b: [[CatOrDog!]]!, $c: Pet) {
          field(a: $a, b: $b, c: $c)
        }
        """,
        [],
        [
          non_input_type("a", "Dog", 1),
          non_input_type("b", "[[CatOrDog!]]!", 1),
          non_input_type("c", "Pet", 1)
        ]
      )
    end

  end

end
