defmodule Absinthe.Phase.Document.Validation.KnownArgumentNamesTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.KnownArgumentNames

  use Support.Harness.Validation
  alias Absinthe.{Blueprint}

  describe "Valid" do

    it "single arg is known" do
      assert_passes_rule(@rule,
        """
        fragment argOnRequiredArg on Dog {
          doesKnowCommand(dogCommand: SIT)
        }
        """,
        []
      )
    end

    it "multiple args are known" do
      assert_passes_rule(@rule,
        """
        fragment multipleArgs on ComplicatedArgs {
          multipleReqs(req1: 1, req2: 2)
        }
        """,
        []
      )
    end

    it "multiple args in reverse order are known" do
      assert_passes_rule(@rule,
        """
        fragment multipleArgsReverseOrder on ComplicatedArgs {
          multipleReqs(req2: 2, req1: 1)
        }
        """,
        []
      )
    end

    it "no args on optional arg" do
      assert_passes_rule(@rule,
        """
        fragment noArgOnOptionalArg on Dog {
          isHousetrained
        }
        """,
        []
      )
    end

    it "args are known deeply" do
      assert_passes_rule(@rule,
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

    it "directive args are known" do
      assert_passes_rule(@rule,
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

    it "undirective args are invalid" do
      assert_fails_rule(@rule,
        """
        {
          dog @skip(unless: true)
        }
        """,
        [],
        [
          bad_value(Blueprint.Input.Argument, @rule.directive_error_message("unless", "skip"), 2, name: "unless")
        ]
      )
    end

    it "invalid arg name" do
      assert_fails_rule(@rule,
        """
        fragment invalidArgName on Dog {
          doesKnowCommand(unknown: true)
        }
        """,
        [],
        [
          bad_value(Blueprint.Input.Argument, @rule.field_error_message("unknown", "doesKnowCommand", "Dog"), 2, name: "unknown")
        ]
      )
    end

    it "unknown args amongst known args" do
      assert_fails_rule(@rule,
        """
        fragment oneGoodArgOneInvalidArg on Dog {
          doesKnowCommand(whoknows: 1, dogCommand: SIT, unknown: true)
        }
        """,
        [],
        [
          bad_value(Blueprint.Input.Argument, @rule.field_error_message("unknown", "doesKnowCommand", "Dog"), 2, name: "unknown"),
          bad_value(Blueprint.Input.Argument, @rule.field_error_message("whoknows", "doesKnowCommand", "Dog"), 2, name: "whoknows")
        ]
      )
    end

    it "unknown args deeply" do
      assert_fails_rule(@rule,
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
          bad_value(Blueprint.Input.Argument, @rule.field_error_message("unknown", "doesKnowCommand", "Dog"), 3, name: "unknown"),
          bad_value(Blueprint.Input.Argument,@rule.field_error_message("unknown", "doesKnowCommand", "Dog"), 8, name: "unknown")
        ]
      )
    end

  end

end
