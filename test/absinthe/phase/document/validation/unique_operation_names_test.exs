defmodule Absinthe.Phase.Document.Validation.UniqueOperationNamesTest do
  @phase Absinthe.Phase.Document.Validation.UniqueOperationNames

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp duplicate_operation(name, line) do
    bad_value(
      Blueprint.Document.Operation,
      @phase.error_message(name),
      line,
      name: name
    )
  end

  describe "Validate: Unique operation names" do
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

    test "one named operation" do
      assert_passes_validation(
        """
        query Foo {
          field
        }
        """,
        []
      )
    end

    test "multiple operations" do
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

    test "multiple operations of different types" do
      assert_passes_validation(
        """
        query Foo {
          field
        }

        mutation Bar {
          field
        }

        subscription Baz {
          field
        }
        """,
        []
      )
    end

    test "fragment and operation named the same" do
      assert_passes_validation(
        """
        query Foo {
          ...Foo
        }
        fragment Foo on Type {
          field
        }
        """,
        []
      )
    end

    test "multiple operations of same name" do
      assert_fails_validation(
        """
        query Foo {
          fieldA
        }
        query Foo {
          fieldB
        }
        """,
        [],
        [
          duplicate_operation("Foo", 1),
          duplicate_operation("Foo", 4)
        ]
      )
    end

    test "multiple ops of same name of different types (mutation)" do
      assert_fails_validation(
        """
        query Foo {
          fieldA
        }
        mutation Foo {
          fieldB
        }
        """,
        [],
        [
          duplicate_operation("Foo", 1),
          duplicate_operation("Foo", 4)
        ]
      )
    end

    test "multiple ops of same name of different types (subscription)" do
      assert_fails_validation(
        """
        query Foo {
          fieldA
        }
        subscription Foo {
          fieldB
        }
        """,
        [],
        [
          duplicate_operation("Foo", 1),
          duplicate_operation("Foo", 4)
        ]
      )
    end
  end
end
