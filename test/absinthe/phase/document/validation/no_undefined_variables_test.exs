defmodule Absinthe.Phase.Document.Validation.NoUndefinedVariablesTest do
  @phase Absinthe.Phase.Document.Validation.NoUndefinedVariables

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp undefined_variable(name, variable_line, operation_name, operation_line) do
    bad_value(
      Blueprint.Input.Variable,
      @phase.error_message(name, operation_name),
      [variable_line, operation_line],
      name: name
    )
  end

  describe "Validate: No undefined variables" do
    test "all variables defined" do
      assert_passes_validation(
        """
        query Foo($a: String, $b: String, $c: String) {
          field(a: $a, b: $b, c: $c)
        }
        """,
        []
      )
    end

    test "all variables deeply defined" do
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

    test "all variables deeply in inline fragments defined" do
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

    test "all variables in fragments deeply defined" do
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

    test "variable within single fragment defined in multiple operations" do
      assert_passes_validation(
        """
        query Foo($a: String) {
          ...FragA
        }
        query Bar($a: String) {
          ...FragA
        }
        fragment FragA on Type {
          field(a: $a)
        }
        """,
        []
      )
    end

    test "variable within fragments defined in operations" do
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

    test "variable within recursive fragment defined" do
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

    test "variable not defined" do
      assert_fails_validation(
        """
        query Foo($a: String, $b: String, $c: String) {
          field(a: $a, b: $b, c: $c, d: $d)
        }
        """,
        [],
        [
          undefined_variable("d", 2, "Foo", 1)
        ]
      )
    end

    test "variable not defined by un-named query" do
      assert_fails_validation(
        """
        {
          field(a: $a)
        }
        """,
        [],
        [
          undefined_variable("a", 2, nil, 1)
        ]
      )
    end

    test "multiple variables not defined" do
      assert_fails_validation(
        """
        query Foo($b: String) {
          field(a: $a, b: $b, c: $c)
        }
        """,
        [],
        [
          undefined_variable("a", 2, "Foo", 1),
          undefined_variable("c", 2, "Foo", 1)
        ]
      )
    end

    test "variable in fragment not defined by un-named query" do
      assert_fails_validation(
        """
        {
          ...FragA
        }
        fragment FragA on Type {
          field(a: $a)
        }
        """,
        [],
        [
          undefined_variable("a", 5, nil, 1)
        ]
      )
    end

    test "variable in fragment not defined by operation" do
      assert_fails_validation(
        """
        query Foo($a: String, $b: String) {
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
        [],
        [
          undefined_variable("c", 15, "Foo", 1)
        ]
      )
    end

    test "multiple variables in fragments not defined" do
      assert_fails_validation(
        """
        query Foo($b: String) {
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
        [],
        [
          undefined_variable("a", 5, "Foo", 1),
          undefined_variable("c", 15, "Foo", 1)
        ]
      )
    end

    test "single variable in fragment not defined by multiple operations" do
      assert_fails_validation(
        """
        query Foo($a: String) {
          ...FragAB
        }
        query Bar($a: String) {
          ...FragAB
        }
        fragment FragAB on Type {
          field(a: $a, b: $b)
        }
        """,
        [],
        [
          undefined_variable("b", 8, "Foo", 1),
          undefined_variable("b", 8, "Bar", 4)
        ]
      )
    end

    test "variables in fragment not defined by multiple operations" do
      assert_fails_validation(
        """
        query Foo($b: String) {
          ...FragAB
        }
        query Bar($a: String) {
          ...FragAB
        }
        fragment FragAB on Type {
          field(a: $a, b: $b)
        }
        """,
        [],
        [
          undefined_variable("a", 8, "Foo", 1),
          undefined_variable("b", 8, "Bar", 4)
        ]
      )
    end

    test "variable in fragment used by other operation" do
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
          undefined_variable("a", 8, "Foo", 1),
          undefined_variable("b", 11, "Bar", 4)
        ]
      )
    end

    test "multiple undefined variables produce multiple errors" do
      assert_fails_validation(
        """
        query Foo($b: String) {
          ...FragAB
        }
        query Bar($a: String) {
          ...FragAB
        }
        fragment FragAB on Type {
          field1(a: $a, b: $b)
          ...FragC
          field3(a: $a, b: $b)
        }
        fragment FragC on Type {
          field2(c: $c)
        }
        """,
        [],
        [
          undefined_variable("a", 8, "Foo", 1),
          undefined_variable("a", 10, "Foo", 1),
          undefined_variable("c", 13, "Foo", 1),
          undefined_variable("b", 8, "Bar", 4),
          undefined_variable("b", 10, "Bar", 4),
          undefined_variable("c", 13, "Bar", 4)
        ]
      )
    end
  end
end
