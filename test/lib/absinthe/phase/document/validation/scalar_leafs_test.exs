defmodule Absinthe.Phase.Document.Validation.ScalarLeafsTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.ScalarLeafs

  use Support.Harness.Validation
  alias Absinthe.{Blueprint}

  defp no_scalar_subselection(node_name, type_name, line) do
    bad_value(
      Blueprint.Document.Field,
      @rule.no_subselection_allowed_message(node_name, type_name),
      line,
      name: node_name
    )
  end

  defp missing_obj_subselection(node_name, type_name, line) do
    bad_value(
      Blueprint.Document.Field,
      @rule.required_subselection_message(node_name, type_name),
      line,
      name: node_name
    )
  end

  describe "Validate: Scalar leafs" do

    it "valid scalar selection" do
      assert_passes_rule(@rule,
        """
        fragment scalarSelection on Dog {
          barks
        }
        """,
        []
      )
    end

    it "object type missing selection" do
      assert_fails_rule(@rule,
        """
        query directQueryOnObjectWithoutSubFields {
          human
        }
        """,
        [],
        missing_obj_subselection("human", "Human", 2)
      )
    end

    it "interface type missing selection" do
      assert_fails_rule(@rule,
        """
        {
          human { pets }
        }
        """,
        [],
        missing_obj_subselection("pets", "[Pet]", 2)
      )
    end

    it "valid scalar selection with args" do
      assert_passes_rule(@rule,
        """
        fragment scalarSelectionWithArgs on Dog {
          doesKnowCommand(dogCommand: SIT)
        }
        """,
        []
      )
    end

    it "scalar selection not allowed on Boolean" do
      assert_fails_rule(@rule,
        """
        fragment scalarSelectionsNotAllowedOnBoolean on Dog {
          barks { sinceWhen }
        }
        """,
        [],
        no_scalar_subselection("barks", "Boolean", 2)
      )
    end

    it "scalar selection not allowed on Enum" do
      assert_fails_rule(@rule,
        """
        fragment scalarSelectionsNotAllowedOnEnum on Cat {
          furColor { inHexdec }
        }
        """,
        [],
        no_scalar_subselection("furColor", "FurColor", 2)
      )
    end

    it "scalar selection not allowed with args" do
      assert_fails_rule(@rule,
        """
        fragment scalarSelectionsNotAllowedWithArgs on Dog {
          doesKnowCommand(dogCommand: SIT) { sinceWhen }
        }
        """,
        [],
        no_scalar_subselection("doesKnowCommand", "Boolean", 2)
      )
    end

    it "Scalar selection not allowed with directives" do
      assert_fails_rule(@rule,
        """
        fragment scalarSelectionsNotAllowedWithDirectives on Dog {
          name @include(if: true) { isAlsoHumanName }
        }
        """,
        [],
        no_scalar_subselection("name", "String", 2)
      )
    end

    it "Scalar selection not allowed with directives and args" do
      assert_fails_rule(@rule,
        """
        fragment scalarSelectionsNotAllowedWithDirectivesAndArgs on Dog {
          doesKnowCommand(dogCommand: SIT) @include(if: true) { sinceWhen }
        }
        """,
        [],
        no_scalar_subselection("doesKnowCommand", "Boolean", 2)
      )
    end

  end

end
