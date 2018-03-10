defmodule Absinthe.Phase.Document.Validation.ScalarLeafsTest do
  @phase Absinthe.Phase.Document.Validation.ScalarLeafs

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.{Blueprint}

  defp no_scalar_subselection(node_name, type_name, line) do
    bad_value(
      Blueprint.Document.Field,
      @phase.no_subselection_allowed_message(node_name, type_name),
      line,
      name: node_name
    )
  end

  defp missing_obj_subselection(node_name, type_name, line) do
    bad_value(
      Blueprint.Document.Field,
      @phase.required_subselection_message(node_name, type_name),
      line,
      name: node_name
    )
  end

  describe "Validate: Scalar leafs" do
    test "valid scalar selection" do
      assert_passes_validation(
        """
        fragment scalarSelection on Dog {
          barks
        }
        """,
        []
      )
    end

    test "object type missing selection" do
      assert_fails_validation(
        """
        query directQueryOnObjectWithoutSubFields {
          human
        }
        """,
        [],
        missing_obj_subselection("human", "Human", 2)
      )
    end

    test "interface type missing selection" do
      assert_fails_validation(
        """
        {
          human { pets }
        }
        """,
        [],
        missing_obj_subselection("pets", "[Pet]", 2)
      )
    end

    test "valid scalar selection with args" do
      assert_passes_validation(
        """
        fragment scalarSelectionWithArgs on Dog {
          doesKnowCommand(dogCommand: SIT)
        }
        """,
        []
      )
    end

    test "scalar selection not allowed on Boolean" do
      assert_fails_validation(
        """
        fragment scalarSelectionsNotAllowedOnBoolean on Dog {
          barks { sinceWhen }
        }
        """,
        [],
        no_scalar_subselection("barks", "Boolean", 2)
      )
    end

    test "scalar selection not allowed on Enum" do
      assert_fails_validation(
        """
        fragment scalarSelectionsNotAllowedOnEnum on Cat {
          furColor { inHexdec }
        }
        """,
        [],
        no_scalar_subselection("furColor", "FurColor", 2)
      )
    end

    test "scalar selection not allowed with args" do
      assert_fails_validation(
        """
        fragment scalarSelectionsNotAllowedWithArgs on Dog {
          doesKnowCommand(dogCommand: SIT) { sinceWhen }
        }
        """,
        [],
        no_scalar_subselection("doesKnowCommand", "Boolean", 2)
      )
    end

    test "Scalar selection not allowed with directives" do
      assert_fails_validation(
        """
        fragment scalarSelectionsNotAllowedWithDirectives on Dog {
          name @include(if: true) { isAlsoHumanName }
        }
        """,
        [],
        no_scalar_subselection("name", "String", 2)
      )
    end

    test "Scalar selection not allowed with directives and args" do
      assert_fails_validation(
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
