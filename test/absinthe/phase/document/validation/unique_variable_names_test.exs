defmodule Absinthe.Phase.Document.Validation.UniqueVariableNamesTest do
  @phase Absinthe.Phase.Document.Validation.UniqueVariableNames

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp duplicate_variable(name, line) do
    bad_value(
      Blueprint.Document.VariableDefinition,
      @phase.error_message(name),
      line,
      name: name
    )
  end

  describe "Validate: Unique variable names" do
    test "unique variable names" do
      assert_passes_validation(
        """
        query A($x: Int, $y: String) { __typename }
        query B($x: String, $y: Int) { __typename }
        """,
        []
      )
    end

    test "duplicate variable names" do
      assert_fails_validation(
        """
        query A($x: Int, $x: Int, $x: String) { __typename }
        query B($x: String, $x: Int) { __typename }
        query C($x: Int, $x: Int) { __typename }
        """,
        [],
        [
          duplicate_variable("x", 1),
          duplicate_variable("x", 2),
          duplicate_variable("x", 3)
        ]
      )
    end
  end
end
