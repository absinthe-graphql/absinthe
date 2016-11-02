defmodule Absinthe.Phase.Document.Validation.NoUndefinedVariablesTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.NoUndefinedVariables

  use Support.Harness.Validation
  alias Absinthe.Blueprint

  defp undefined_variable(name, variable_line, operation_name, operation_line) do
    bad_value(
      Blueprint.Input.Variable,
      @rule.error_message(name, operation_name),
      [variable_line, operation_line],
      name: name
    )
  end

  describe "Validate: No undefined variables" do

    it "all variables defined" do
      assert_passes_rule(@rule,
        """
        query Foo($a: String, $b: String, $c: String) {
          field(a: $a, b: $b, c: $c)
        }
        """,
        []
      )
    end

    it "all variables deeply defined" do
      assert_passes_rule(@rule,
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

    it "all variables deeply in inline fragments defined" do
      assert_passes_rule(@rule,
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

    it "all variables in fragments deeply defined" do
      assert_passes_rule(@rule,
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

    it "variable within single fragment defined in multiple operations" do
      assert_passes_rule(@rule,
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

    it "variable within fragments defined in operations" do
      assert_passes_rule(@rule,
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

    it "variable within recursive fragment defined" do
      assert_passes_rule(@rule,
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

    it "variable not defined" do
      assert_fails_rule(@rule,
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

    it "variable not defined by un-named query" do
      assert_fails_rule(@rule,
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

    it "multiple variables not defined" do
      assert_fails_rule(@rule,
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

    it "variable in fragment not defined by un-named query" do
      assert_fails_rule(@rule,
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

    it "variable in fragment not defined by operation" do
      assert_fails_rule(@rule,
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

    it "multiple variables in fragments not defined" do
      assert_fails_rule(@rule,
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

    it "single variable in fragment not defined by multiple operations" do
      assert_fails_rule(@rule,
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

    it "variables in fragment not defined by multiple operations" do
      assert_fails_rule(@rule,
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

    it "variable in fragment used by other operation" do
      assert_fails_rule(@rule,
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

    it "multiple undefined variables produce multiple errors" do
      assert_fails_rule(@rule,
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
          undefined_variable("c", 13, "Bar", 4),
        ]
      )
    end

  end

end
