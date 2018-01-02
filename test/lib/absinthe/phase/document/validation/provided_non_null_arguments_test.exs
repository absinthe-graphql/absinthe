defmodule Absinthe.Phase.Document.Validation.ProvidedNonNullArgumentsTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.ProvidedNonNullArguments

  use Support.Harness.Validation
  alias Absinthe.{Blueprint}

  context "Validate: Provided required arguments" do

    test "ignores unknown arguments" do
      assert_passes_rule(@rule,
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

    context "Valid non-nullable value" do

      test "Arg on optional arg" do
        assert_passes_rule(@rule,
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

      test "No Arg on optional arg" do
        assert_passes_rule(@rule,
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

      test "Multiple args" do
        assert_passes_rule(@rule,
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

      test "Multiple args reverse order" do
        assert_passes_rule(@rule,
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

      test "No args on multiple optional" do
        assert_passes_rule(@rule,
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

      test "One arg on multiple optional" do
        assert_passes_rule(@rule,
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

      test "Second arg on multiple optional" do
        assert_passes_rule(@rule,
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

      test "Multiple reqs on mixedList" do
        assert_passes_rule(@rule,
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

      test "Multiple reqs and one opt on mixedList" do
        assert_passes_rule(@rule,
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

      test "All reqs and opts on mixedList" do
        assert_passes_rule(@rule,
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


    context "Invalid non-nullable value" do

      test "Missing one non-nullable argument" do
        assert_fails_rule(@rule,
          """
          {
            complicatedArgs {
              multipleReqs(req2: 2)
            }
          }
          """,
          [],
          bad_value(Blueprint.Input.Argument, @rule.error_message("req1", "Int!"), 3, name: "req1")
        )
      end

      test "Missing one non-nullable argument using a variable" do
        assert_fails_rule(@rule,
          """
          query WithReq1Blank($value: Int) {
            complicatedArgs {
              multipleReqs(req1: $value, req2: 2)
            }
          }
          """,
          [],
          bad_value(Blueprint.Input.Argument, @rule.error_message("req1", "Int!"), 3, name: "req1")
        )
      end

      test "Missing multiple non-nullable arguments" do
        assert_fails_rule(@rule,
          """
          {
            complicatedArgs {
              multipleReqs
            }
          }
          """,
          [],
          [
            bad_value(Blueprint.Input.Argument, @rule.error_message("req1", "Int!"), 3, name: "req1"),
            bad_value(Blueprint.Input.Argument, @rule.error_message("req2", "Int!"), 3, name: "req2")
          ]
        )
      end

      test "Incorrect value and missing argument" do
        assert_fails_rule(@rule,
          """
          {
            complicatedArgs {
              multipleReqs(req1: "one")
            }
          }
          """,
          [],
          bad_value(Blueprint.Input.Argument, @rule.error_message("req2", "Int!"), 3, name: "req2")
        )
      end

    end

    context "Directive arguments" do

      test "ignores unknown directives" do
        assert_passes_rule(@rule,
        """
          {
            dog @unknown
          }
          """,
        []
      )
      end

      test "with directives of valid types" do
        assert_passes_rule(@rule,
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

      test "with directive with missing types" do
        assert_fails_rule(@rule,
          """
          {
            dog @include {
              name @skip
            }
          }
          """,
          [],
          [
            bad_value(Blueprint.Input.Argument, @rule.error_message("if", "Boolean!"), 2, name: "if"),
            bad_value(Blueprint.Input.Argument, @rule.error_message("if", "Boolean!"), 3, name: "if"),
          ]
        )
      end

    end

  end

end
