defmodule Absinthe.Phase.Document.Validation.NoUnusedVariablesTest do
  @phase Absinthe.Phase.Document.Validation.NoUnusedVariables

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp unused_variable(name, operation_name, operation_line) do
    bad_value(
      Blueprint.Document.VariableDefinition,
      @phase.error_message(name, operation_name),
      operation_line,
      name: name
    )
  end

  describe "Validate: No unused variables" do
    test "uses all variables" do
      assert_passes_validation(
        """
        query ($a: String, $b: String, $c: String) {
          field(a: $a, b: $b, c: $c)
        }
        """,
        []
      )
    end

    test "uses all variables deeply" do
      assert_passes_validation(
        """
        query Foo($a: String, $b: String, $c: String) {
          field(a: $a) {
            field(b: $b) {
              field(c: $c)
            }
          }
        }
        """,
        []
      )
    end

    test "uses all variables deeply in inline fragments" do
      assert_passes_validation(
        """
        query Foo($a: String, $b: String, $c: String) {
          ... on Type {
            field(a: $a) {
              field(b: $b) {
                ... on Type {
                  field(c: $c)
                }
              }
            }
          }
        }
        """,
        []
      )
    end

    test "uses all variables in fragments" do
      assert_passes_validation(
        """
        query Foo($a: String, $b: String, $c: String) {
          ...FragA
        }
        fragment FragA on Type {
          field(a: $a) {
            ...FragB
          }
        }
        fragment FragB on Type {
          field(b: $b) {
            ...FragC
          }
        }
        fragment FragC on Type {
          field(c: $c)
        }
        """,
        []
      )
    end

    test "variable used by fragment in multiple operations" do
      assert_passes_validation(
        """
        query Foo($a: String) {
          ...FragA
        }
        query Bar($b: String) {
          ...FragB
        }
        fragment FragA on Type {
          field(a: $a)
        }
        fragment FragB on Type {
          field(b: $b)
        }
        """,
        []
      )
    end

    test "variable used by recursive fragment" do
      assert_passes_validation(
        """
        query Foo($a: String) {
          ...FragA
        }
        fragment FragA on Type {
          field(a: $a) {
            ...FragA
          }
        }
        """,
        []
      )
    end

    test "variable not used" do
      assert_fails_validation(
        """
        query ($a: String, $b: String, $c: String) {
          field(a: $a, b: $b)
        }
        """,
        [],
        [
          unused_variable("c", nil, 1)
        ]
      )
    end

    test "multiple variables not used" do
      assert_fails_validation(
        """
        query Foo($a: String, $b: String, $c: String) {
          field(b: $b)
        }
        """,
        [],
        [
          unused_variable("a", "Foo", 1),
          unused_variable("c", "Foo", 1)
        ]
      )
    end

    test "variable not used in fragments" do
      assert_fails_validation(
        """
        query Foo($a: String, $b: String, $c: String) {
          ...FragA
        }
        fragment FragA on Type {
          field(a: $a) {
            ...FragB
          }
        }
        fragment FragB on Type {
          field(b: $b) {
            ...FragC
          }
        }
        fragment FragC on Type {
          field
        }
        """,
        [],
        [
          unused_variable("c", "Foo", 1)
        ]
      )
    end

    test "multiple variables not used in fragments" do
      assert_fails_validation(
        """
        query Foo($a: String, $b: String, $c: String) {
          ...FragA
        }
        fragment FragA on Type {
          field {
            ...FragB
          }
        }
        fragment FragB on Type {
          field(b: $b) {
            ...FragC
          }
        }
        fragment FragC on Type {
          field
        }
        """,
        [],
        [
          unused_variable("a", "Foo", 1),
          unused_variable("c", "Foo", 1)
        ]
      )
    end

    test "variable not used by unreferenced fragment" do
      assert_fails_validation(
        """
        query Foo($b: String) {
          ...FragA
        }
        fragment FragA on Type {
          field(a: $a)
        }
        fragment FragB on Type {
          field(b: $b)
        }
        """,
        [],
        [
          unused_variable("b", "Foo", 1)
        ]
      )
    end

    test "variable not used by fragment used by other operation" do
      assert_fails_validation(
        """
        query Foo($b: String) {
          ...FragA
        }
        query Bar($a: String) {
          ...FragB
        }
        fragment FragA on Type {
          field(a: $a)
        }
        fragment FragB on Type {
          field(b: $b)
        }
        """,
        [],
        [
          unused_variable("b", "Foo", 1),
          unused_variable("a", "Bar", 4)
        ]
      )
    end
  end
end
