defmodule Absinthe.Phase.Document.Validation.UniqueVariableNamesTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.UniqueVariableNames

  use Support.Harness.Validation
  alias Absinthe.Blueprint

  defp duplicate_variable(name, line) do
    bad_value(
      Blueprint.Document.VariableDefinition,
      @rule.error_message(name),
      line,
      name: name
    )
  end

  context "Validate: Unique variable names" do

    test "unique variable names" do
      assert_passes_rule(@rule,
        """
        query A($x: Int, $y: String) { __typename }
        query B($x: String, $y: Int) { __typename }
        """,
        []
      )
    end

    test "duplicate variable names" do
      assert_fails_rule(@rule,
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
