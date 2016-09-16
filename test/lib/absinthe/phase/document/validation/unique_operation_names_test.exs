defmodule Absinthe.Phase.Document.Validation.UniqueOperationNamesTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.UniqueOperationNames

  use Support.Harness.Validation
  alias Absinthe.Blueprint

  defp duplicate_operation(name, line) do
    bad_value(
      Blueprint.Document.Operation,
      @rule.error_message(name),
      line,
      name: name
    )
  end

  describe "Validate: Unique operation names" do

    it "no operations" do
      assert_passes_rule(@rule,
        """
        fragment fragA on Type {
          field
        }
        """,
        %{}
      )
    end

    it "one anon operation" do
      assert_passes_rule(@rule,
        """
        {
          field
        }
        """,
        %{}
      )
    end

    it "one named operation" do
      assert_passes_rule(@rule,
        """
        query Foo {
          field
        }
        """,
        %{}
      )
    end

    it "multiple operations" do
      assert_passes_rule(@rule,
        """
        query Foo {
          field
        }

        query Bar {
          field
        }
        """,
        %{}
      )
    end

    it "multiple operations of different types" do
      assert_passes_rule(@rule,
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
        %{}
      )
    end

    it "fragment and operation named the same" do
      assert_passes_rule(@rule,
        """
        query Foo {
          ...Foo
        }
        fragment Foo on Type {
          field
        }
        """,
        %{}
      )
    end

    it "multiple operations of same name" do
      assert_fails_rule(@rule,
        """
        query Foo {
          fieldA
        }
        query Foo {
          fieldB
        }
        """,
        %{},
        [
          duplicate_operation("Foo", 1),
          duplicate_operation("Foo", 4)
        ]
      )
    end

    it "multiple ops of same name of different types (mutation)" do
      assert_fails_rule(@rule,
        """
        query Foo {
          fieldA
        }
        mutation Foo {
          fieldB
        }
        """,
        %{},
        [
          duplicate_operation("Foo", 1),
          duplicate_operation("Foo", 4)
        ]
      )
    end

    it "multiple ops of same name of different types (subscription)" do
      assert_fails_rule(@rule,
        """
        query Foo {
          fieldA
        }
        subscription Foo {
          fieldB
        }
        """,
        %{},
        [
          duplicate_operation("Foo", 1),
          duplicate_operation("Foo", 4)
        ]
      )
    end

  end

end
