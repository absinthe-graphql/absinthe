defmodule Absinthe.Phase.Document.Validation.ProvidedNonNullArgumentsTest do
  @phase Absinthe.Phase.Document.Validation.ProvidedNonNullArguments

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.{Blueprint}

  test "ignores unknown arguments" do
    assert_passes_validation(
      """
      {
        dog {
          isHousetrained(unknownArgument: true)
        }
      }
      """,
      []
    )
  end

  describe "Valid non-nullable value" do
    test "with a valid non-nullable value: Arg on optional arg" do
      assert_passes_validation(
        """
        {
          dog {
            isHousetrained(atOtherHomes: true)
          }
        }
        """,
        []
      )
    end

    test "with a valid non-nullable value: No Arg on optional arg" do
      assert_passes_validation(
        """
        {
          dog {
            isHousetrained
          }
        }
        """,
        []
      )
    end

    test "with a valid non-nullable value: Multiple args" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleReqs(req1: 1, req2: 2)
          }
        }
        """,
        []
      )
    end

    test "with a valid non-nullable value: Multiple args reverse order" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleReqs(req2: 2, req1: 1)
          }
        }
        """,
        []
      )
    end

    test "with a valid non-nullable value: No args on multiple optional" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOpts
          }
        }
        """,
        []
      )
    end

    test "with a valid non-nullable value: One arg on multiple optional" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOpts(opt1: 1)
          }
        }
        """,
        []
      )
    end

    test "with a valid non-nullable value: Second arg on multiple optional" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOpts(opt2: 1)
          }
        }
        """,
        []
      )
    end

    test "with a valid non-nullable value: Multiple reqs on mixedList" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOptAndReq(req1: 3, req2: 4)
          }
        }
        """,
        []
      )
    end

    test "with a valid non-nullable value: Multiple reqs and one opt on mixedList" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOptAndReq(req1: 3, req2: 4, opt1: 5)
          }
        }
        """,
        []
      )
    end

    test "with a valid non-nullable value: All reqs and opts on mixedList" do
      assert_passes_validation(
        """
        {
          complicatedArgs {
            multipleOptAndReq(req1: 3, req2: 4, opt1: 5, opt2: 6)
          }
        }
        """,
        []
      )
    end
  end

  describe "Invalid non-nullable value" do
    test "with an invalid non-nullable value: Missing one non-nullable argument" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            multipleReqs(req2: 2)
          }
        }
        """,
        [],
        bad_value(Blueprint.Input.Argument, @phase.error_message("req1", "Int!"), 3, name: "req1")
      )
    end

    test "with an invalid non-nullable value: Missing one non-nullable argument using a variable" do
      assert_fails_validation(
        """
        query WithReq1Blank($value: Int) {
          complicatedArgs {
            multipleReqs(req1: $value, req2: 2)
          }
        }
        """,
        [],
        bad_value(Blueprint.Input.Argument, @phase.error_message("req1", "Int!"), 3, name: "req1")
      )
    end

    test "with an invalid non-nullable value: Missing multiple non-nullable arguments" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            multipleReqs
          }
        }
        """,
        [],
        [
          bad_value(
            Blueprint.Input.Argument,
            @phase.error_message("req1", "Int!"),
            3,
            name: "req1"
          ),
          bad_value(
            Blueprint.Input.Argument,
            @phase.error_message("req2", "Int!"),
            3,
            name: "req2"
          )
        ]
      )
    end

    test "with an invalid non-nullable value: Incorrect value and missing argument" do
      assert_fails_validation(
        """
        {
          complicatedArgs {
            multipleReqs(req1: "one")
          }
        }
        """,
        [],
        bad_value(Blueprint.Input.Argument, @phase.error_message("req2", "Int!"), 3, name: "req2")
      )
    end
  end

  describe "Directive arguments" do
    test "for directive arguments, ignores unknown directives" do
      assert_passes_validation(
        """
        {
          dog @unknown
        }
        """,
        []
      )
    end

    test "for directive arguments, with directives of valid types" do
      assert_passes_validation(
        """
        {
          dog @include(if: true) {
            name
          }
          human @skip(if: false) {
            name
          }
        }
        """,
        []
      )
    end

    test "for directive arguments, with directive with missing types" do
      assert_fails_validation(
        """
        {
          dog @include {
            name @skip
          }
        }
        """,
        [],
        [
          bad_value(
            Blueprint.Input.Argument,
            @phase.error_message("if", "Boolean!"),
            2,
            name: "if"
          ),
          bad_value(
            Blueprint.Input.Argument,
            @phase.error_message("if", "Boolean!"),
            3,
            name: "if"
          )
        ]
      )
    end
  end
end
