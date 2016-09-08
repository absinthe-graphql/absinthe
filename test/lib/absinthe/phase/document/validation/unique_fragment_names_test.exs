defmodule Absinthe.Phase.Document.Validation.UniqueFragmentNamesTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.UniqueFragmentNames

  use Support.Harness.Validation
  alias Absinthe.Blueprint

  defp duplicate_fragment(name, line) do
    bad_value(
      Blueprint.Document.Fragment.Named,
      @rule.error_message(name),
      line,
      name: name
    )
  end

  describe "Validate: Unique fragment names" do

    it "no fragments" do
      assert_passes_rule(@rule,
        """
        {
          field
        }
        """,
        %{}
      )
    end

    it "one fragment" do
      assert_passes_rule(@rule,
        """
        {
          ...fragA
        }

        fragment fragA on Type {
          field
        }
        """,
        %{}
      )
    end

    it "many fragments" do
      assert_passes_rule(@rule,
        """
        {
          ...fragA
          ...fragB
          ...fragC
        }
        fragment fragA on Type {
          fieldA
        }
        fragment fragB on Type {
          fieldB
        }
        fragment fragC on Type {
          fieldC
        }
        """,
        %{}
      )
    end

    it "inline fragments are always unique" do
      assert_passes_rule(@rule,
        """
        {
          ...on Type {
            fieldA
          }
          ...on Type {
            fieldB
          }
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

    it "fragments named the same" do
      assert_fails_rule(@rule,
        """
        {
          ...fragA
        }
        fragment fragA on Type {
          fieldA
        }
        fragment fragA on Type {
          fieldB
        }
        """,
        %{},
        [
          duplicate_fragment("fragA", 4),
          duplicate_fragment("fragA", 7)
        ]
      )
    end

    it "fragments named the same without being referenced" do
      assert_fails_rule(@rule,
        """
        fragment fragA on Type {
          fieldA
        }
        fragment fragA on Type {
          fieldB
        }
        """,
        %{},
        [
          duplicate_fragment("fragA", 1),
          duplicate_fragment("fragA", 4)
        ]
      )
    end

  end

end
