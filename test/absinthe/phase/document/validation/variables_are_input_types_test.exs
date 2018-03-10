defmodule Absinthe.Phase.Document.Validation.VariablesAreInputTypesTest do
  @phase Absinthe.Phase.Document.Validation.VariablesAreInputTypes

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp non_input_type(name, type_rep, line) do
    bad_value(
      Blueprint.Document.VariableDefinition,
      @phase.error_message(name, type_rep),
      line,
      name: name
    )
  end

  describe "Validate: Variables are input types" do
    test "input types are valid" do
      assert_passes_validation(
        """
          query Foo($a: String, $b: [Boolean!]!, $c: ComplexInput) {
            field(a: $a, b: $b, c: $c)
          }
        """,
        []
      )
    end

    test "output types are invalid" do
      assert_fails_validation(
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
