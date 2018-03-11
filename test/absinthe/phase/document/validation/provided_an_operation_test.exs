defmodule Absinthe.Phase.Document.Validation.ProvidedAnOperationTest do
  @phase Absinthe.Phase.Document.Validation.ProvidedAnOperation

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp no_operation do
    bad_value(
      Blueprint,
      @phase.error_message,
      nil
    )
  end

  describe "Given an operation" do
    test "passes" do
      assert_passes_validation(
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
    test "fails" do
      assert_fails_validation(
        "",
        [],
        no_operation()
      )
    end
  end

  describe "When given fragments" do
    test "fails" do
      assert_fails_validation(
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
