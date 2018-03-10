defmodule Absinthe.Phase.Document.Validation.LoneAnonymousOperationTest do
  @phase Absinthe.Phase.Document.Validation.LoneAnonymousOperation

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp anon_not_alone(line) do
    bad_value(
      Blueprint.Document.Operation,
      "This anonymous operation must be the only defined operation.",
      line
    )
  end

  describe "Validate: Anonymous operation must be alone" do
    test "no operations" do
      assert_passes_validation(
        """
        fragment fragA on Type {
          field
        }
        """,
        []
      )
    end

    test "one anon operation" do
      assert_passes_validation(
        """
        {
          field
        }
        """,
        []
      )
    end

    test "multiple named operations" do
      assert_passes_validation(
        """
        query Foo {
          field
        }

        query Bar {
          field
        }
        """,
        []
      )
    end

    test "anon operation with fragment" do
      assert_passes_validation(
        """
        {
          ...Foo
        }
        fragment Foo on Type {
          field
        }
        """,
        []
      )
    end

    test "multiple anon operations" do
      assert_fails_validation(
        """
        {
          fieldA
        }
        {
          fieldB
        }
        """,
        [],
        [
          anon_not_alone(1),
          anon_not_alone(4)
        ]
      )
    end

    test "anon operation with a mutation" do
      assert_fails_validation(
        """
        {
          fieldA
        }
        mutation Foo {
          fieldB
        }
        """,
        [],
        [
          anon_not_alone(1)
        ]
      )
    end

    test "anon operation with a subscription" do
      assert_fails_validation(
        """
        {
          fieldA
        }
        subscription Foo {
          fieldB
        }
        """,
        [],
        [
          anon_not_alone(1)
        ]
      )
    end
  end
end
