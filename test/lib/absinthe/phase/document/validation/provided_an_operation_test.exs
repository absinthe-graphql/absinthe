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

  describe "Given an operation" do

    it "passes" do
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

  describe "When empty" do

    it "fails" do
      assert_fails_rule(@rule,
        "",
        [],
        no_operation()
      )
    end

  end

  describe "When given fragments" do

    it "fails" do
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
