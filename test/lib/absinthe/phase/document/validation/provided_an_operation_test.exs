defmodule Absinthe.Phase.Document.Validation.ProvidedAnOperationTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.ProvidedAnOperation

  use Support.Harness.Validation
  alias Absinthe.Blueprint

  defp no_operation do
    bad_value(
      Blueprint,
      @rule.error_message,
      nil
    )
  end

  context "Given an operation" do

    test "passes" do
      assert_passes_rule(@rule,
        """
        query Bar {
          name
        }
        """,
        []
      )
    end

  end

  context "When empty" do

    test "fails" do
      assert_fails_rule(@rule,
        "",
        [],
        no_operation()
      )
    end

  end

  context "When given fragments" do

    test "fails" do
      assert_fails_rule(@rule,
        """
        fragment Foo on QueryRootType {
          name
        }
        """,
        [],
        no_operation()
      )
    end

  end

end
