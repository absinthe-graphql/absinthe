defmodule Absinthe.Phase.Document.Validation.SelectedCurrentOperationTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.SelectedCurrentOperation

  use Support.Harness.Validation
  alias Absinthe.Blueprint

  defp no_current_operation do
    bad_value(
      Blueprint,
      @rule.error_message,
      nil
    )
  end

  context "Given an operation name" do

    it "passes when the operation is provided" do
      assert_passes_rule(@rule,
        """
        query Bar {
          name
        }
        query Foo {
          name
        }
        """,
        [operation_name: "Foo"]
      )
    end

    it "fails when the operation is not provided" do
      assert_fails_rule(@rule,
        """
        query Bar {
          name
        }
        query Foo {
          name
        }
        """,
        [operation_name: "Nothere"],
        no_current_operation()
      )
    end

    it "fails when a single operation with wrong name is provided" do
      assert_fails_rule(@rule,
        """
        query Foo {
          name
        }
        """,
        [operation_name: "Nothere"],
        no_current_operation()
      )
    end

  end

  context "Not given an operation name" do

    it "passes when only one operation is given and is named" do
      assert_passes_rule(@rule,
        """
        query Bar {
          name
        }
        """,
        []
      )
    end
    it "passes when only one operation is given anonymously" do
      assert_passes_rule(@rule,
        """
        {
          name
        }
        """,
        []
      )
    end

    it "fails when more that one operation is given" do
      assert_fails_rule(@rule,
        """
        query Bar {
          name
        }
        query Foo {
          name
        }
        """,
        [],
        no_current_operation()
      )
    end

  end

end
