defmodule Absinthe.Phase.Document.Validation.VariablesInAllowedPositionTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.VariablesInAllowedPosition

  use Support.Harness.Validation
  alias Absinthe.{Blueprint}

  defp bad_position(variable_name, variable_type, position_type, lines) do
    bad_value(
      Blueprint.Input.Variable,
      @rule.error_message(variable_name, variable_type, position_type),
      lines,
      name: variable_name
    )
  end

  describe "Validate: Variables are in allowed positions" do

    it "Boolean => Boolean" do
      assert_passes_rule(@rule,
        """
        query Query($booleanArg: Boolean)
        {
          complicatedArgs {
            booleanArgField(booleanArg: $booleanArg)
          }
        }
        """,
        %{}
      )
    end

    it "Boolean => Boolean within fragment" do
      assert_passes_rule(@rule,
        """
        fragment booleanArgFrag on ComplicatedArgs {
          booleanArgField(booleanArg: $booleanArg)
        }
        query Query($booleanArg: Boolean)
        {
          complicatedArgs {
            ...booleanArgFrag
          }
        }
        """,
        %{}
      )
      assert_passes_rule(@rule,
        """
        query Query($booleanArg: Boolean)
        {
          complicatedArgs {
            ...booleanArgFrag
          }
        }
        fragment booleanArgFrag on ComplicatedArgs {
          booleanArgField(booleanArg: $booleanArg)
        }
        """,
        %{}
      )
    end

    it "Boolean! => Boolean" do
      assert_passes_rule(@rule,
        """
        query Query($nonNullBooleanArg: Boolean!)
        {
          complicatedArgs {
            booleanArgField(booleanArg: $nonNullBooleanArg)
          }
        }
        """,
        %{}
      )
    end

    it "Boolean! => Boolean within fragment" do
      assert_passes_rule(@rule,
        """
        fragment booleanArgFrag on ComplicatedArgs {
          booleanArgField(booleanArg: $nonNullBooleanArg)
        }

        query Query($nonNullBooleanArg: Boolean!)
        {
          complicatedArgs {
            ...booleanArgFrag
          }
        }
        """,
        %{}
      )
    end

    it "Int => Int! with default" do
      assert_passes_rule(@rule,
        """
        query Query($intArg: Int = 1)
        {
          complicatedArgs {
            nonNullIntArgField(nonNullIntArg: $intArg)
          }
        }
        """,
        %{}
      )
    end

    it "[String] => [String]" do
      assert_passes_rule(@rule,
        """
        query Query($stringListVar: [String])
        {
          complicatedArgs {
            stringListArgField(stringListArg: $stringListVar)
          }
        }
        """,
        %{}
      )
    end

    it "[String!] => [String]" do
      assert_passes_rule(@rule,
        """
        query Query($stringListVar: [String!])
        {
          complicatedArgs {
            stringListArgField(stringListArg: $stringListVar)
          }
        }
        """,
        %{}
      )
    end

    it "String => [String] in item position" do
      assert_passes_rule(@rule,
        """
        query Query($stringVar: String)
        {
          complicatedArgs {
            stringListArgField(stringListArg: [$stringVar])
          }
        }
        """,
        %{}
      )
    end

    it "String! => [String] in item position" do
      assert_passes_rule(@rule,
        """
        query Query($stringVar: String!)
        {
          complicatedArgs {
            stringListArgField(stringListArg: [$stringVar])
          }
        }
        """,
        %{}
      )
    end

    it "ComplexInput => ComplexInput" do
      assert_passes_rule(@rule,
        """
        query Query($complexVar: ComplexInput)
        {
          complicatedArgs {
            complexArgField(complexArg: $complexVar)
          }
        }
        """,
        %{}
      )
    end

    it "ComplexInput => ComplexInput in field position" do
      assert_passes_rule(@rule,
        """
        query Query($boolVar: Boolean = false)
        {
          complicatedArgs {
            complexArgField(complexArg: {requiredArg: $boolVar})
          }
        }
        """,
        %{}
      )
    end

    it "Boolean! => Boolean! in directive" do
      assert_passes_rule(@rule,
        """
        query Query($boolVar: Boolean!)
        {
          dog @include(if: $boolVar)
        }
        """,
        %{}
      )
    end

    it "Boolean => Boolean! in directive with default" do
      assert_passes_rule(@rule,
        """
        query Query($boolVar: Boolean = false)
        {
          dog @include(if: $boolVar)
        }
        """,
        %{}
      )
    end

    it "Int => Int!" do
      assert_fails_rule(@rule,
        """
        query Query($intArg: Int) {
          complicatedArgs {
            nonNullIntArgField(nonNullIntArg: $intArg)
          }
        }
        """,
        %{},
        bad_position("intArg", "Int", "Int!", [1, 3])
      )
    end

    it "Int => Int! within fragment" do
      assert_fails_rule(@rule,
        """
        fragment nonNullIntArgFieldFrag on ComplicatedArgs {
          nonNullIntArgField(nonNullIntArg: $intArg)
        }

        query Query($intArg: Int) {
          complicatedArgs {
            ...nonNullIntArgFieldFrag
          }
        }
        """,
        %{},
        bad_position("intArg", "Int", "Int!", [5, 2])
      )
    end

    it "Int => Int! within nested fragment" do
      assert_fails_rule(@rule,
        """
        fragment outerFrag on ComplicatedArgs {
          ...nonNullIntArgFieldFrag
        }

        fragment nonNullIntArgFieldFrag on ComplicatedArgs {
          nonNullIntArgField(nonNullIntArg: $intArg)
        }

        query Query($intArg: Int) {
          complicatedArgs {
            ...outerFrag
          }
        }
        """,
        %{},
        bad_position("intArg", "Int", "Int!", [9, 6])
      )
    end

    it "String over Boolean" do
      assert_fails_rule(@rule,
        """
        query Query($stringVar: String) {
          complicatedArgs {
            booleanArgField(booleanArg: $stringVar)
          }
        }
        """,
        %{},
        bad_position("stringVar", "String", "Boolean", [1, 3])
      )
    end

    it "String => [String]" do
      assert_fails_rule(@rule,
        """
        query Query($stringVar: String) {
          complicatedArgs {
            stringListArgField(stringListArg: $stringVar)
          }
        }
        """,
        %{},
        bad_position("stringVar", "String", "[String]", [1, 3])
      )
    end

    it "Boolean => Boolean! in directive" do
      assert_fails_rule(@rule,
        """
        query Query($boolVar: Boolean) {
          dog @include(if: $boolVar)
        }
        """,
        %{},
        bad_position("boolVar", "Boolean", "Boolean!", [1, 2])
      )
    end

    it "String => Boolean! in directive" do
      assert_fails_rule(@rule,
        """
        query Query($stringVar: String) {
          dog @include(if: $stringVar)
        }
        """,
        %{},
        bad_position("stringVar", "String", "Boolean!", [1, 2])
      )
    end

  end

end
