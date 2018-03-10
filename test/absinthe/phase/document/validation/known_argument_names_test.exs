defmodule Absinthe.Phase.Document.Validation.KnownArgumentNamesTest do
  @phase Absinthe.Phase.Document.Validation.KnownArgumentNames

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.{Blueprint}

  describe "Valid" do
    test "single arg is known" do
      assert_passes_validation(
        """
        fragment argOnRequiredArg on Dog {
          doesKnowCommand(dogCommand: SIT)
        }
        """,
        []
      )
    end

    test "multiple args are known" do
      assert_passes_validation(
        """
        fragment multipleArgs on ComplicatedArgs {
          multipleReqs(req1: 1, req2: 2)
        }
        """,
        []
      )
    end

    test "multiple args in reverse order are known" do
      assert_passes_validation(
        """
        fragment multipleArgsReverseOrder on ComplicatedArgs {
          multipleReqs(req2: 2, req1: 1)
        }
        """,
        []
      )
    end

    test "no args on optional arg" do
      assert_passes_validation(
        """
        fragment noArgOnOptionalArg on Dog {
          isHousetrained
        }
        """,
        []
      )
    end

    test "args are known deeply" do
      assert_passes_validation(
        """
        {
          dog {
            doesKnowCommand(dogCommand: SIT)
          }
          human {
            pet {
              ... on Dog {
                doesKnowCommand(dogCommand: SIT)
              }
            }
          }
        }
        """,
        []
      )
    end

    test "directive args are known" do
      assert_passes_validation(
        """
        {
          dog @skip(if: true)
        }
        """,
        []
      )
    end
  end

  describe "Invalid" do
    test "undirective args are invalid" do
      assert_fails_validation(
        """
        {
          dog @skip(unless: true)
        }
        """,
        [],
        [
          bad_value(
            Blueprint.Input.Argument,
            @phase.directive_error_message("unless", "skip"),
            2,
            name: "unless"
          )
        ]
      )
    end

    test "invalid arg name" do
      assert_fails_validation(
        """
        fragment invalidArgName on Dog {
          doesKnowCommand(unknown: true)
        }
        """,
        [],
        [
          bad_value(
            Blueprint.Input.Argument,
            @phase.field_error_message("unknown", "doesKnowCommand", "Dog"),
            2,
            name: "unknown"
          )
        ]
      )
    end

    test "unknown args amongst known args" do
      assert_fails_validation(
        """
        fragment oneGoodArgOneInvalidArg on Dog {
          doesKnowCommand(whoknows: 1, dogCommand: SIT, unknown: true)
        }
        """,
        [],
        [
          bad_value(
            Blueprint.Input.Argument,
            @phase.field_error_message("unknown", "doesKnowCommand", "Dog"),
            2,
            name: "unknown"
          ),
          bad_value(
            Blueprint.Input.Argument,
            @phase.field_error_message("whoknows", "doesKnowCommand", "Dog"),
            2,
            name: "whoknows"
          )
        ]
      )
    end

    test "unknown args deeply" do
      assert_fails_validation(
        """
        {
          dog {
            doesKnowCommand(unknown: true)
          }
          human {
            pet {
              ... on Dog {
                doesKnowCommand(unknown: true)
              }
            }
          }
        }
        """,
        [],
        [
          bad_value(
            Blueprint.Input.Argument,
            @phase.field_error_message("unknown", "doesKnowCommand", "Dog"),
            3,
            name: "unknown"
          ),
          bad_value(
            Blueprint.Input.Argument,
            @phase.field_error_message("unknown", "doesKnowCommand", "Dog"),
            8,
            name: "unknown"
          )
        ]
      )
    end
  end
end
