defmodule Absinthe.Phase.Document.Validation.NoUnusedFragmentsTest do
  use Absinthe.Case, async: true

  @rule Absinthe.Phase.Document.Validation.NoUnusedFragments

  use Support.Harness.Validation
  alias Absinthe.Blueprint

  defp unused_fragment(name, line) do
    bad_value(
      Blueprint.Document.Fragment.Named,
      @rule.error_message(name),
      line,
      name: name
    )
  end

  describe "Validate: No unused fragments" do

    it "all fragment names are used" do
      assert_passes_rule(@rule,
        """
        {
          human(id: 4) {
            ...HumanFields1
            ... on Human {
              ...HumanFields2
            }
          }
        }
        fragment HumanFields1 on Human {
          name
          ...HumanFields3
        }
        fragment HumanFields2 on Human {
          name
        }
        fragment HumanFields3 on Human {
          name
        }
        """,
        %{}
      )
    end


    it "all fragment names are used by multiple operations" do
      assert_passes_rule(@rule,
        """
        query Foo {
          human(id: 4) {
            ...HumanFields1
          }
        }
        query Bar {
          human(id: 4) {
            ...HumanFields2
          }
        }
        fragment HumanFields1 on Human {
          name
          ...HumanFields3
        }
        fragment HumanFields2 on Human {
          name
        }
        fragment HumanFields3 on Human {
          name
        }
        """,
        %{}
      )
    end

    it "contains unknown fragments" do
      assert_fails_rule(@rule,
        """
        query Foo {
          human(id: 4) {
            ...HumanFields1
          }
        }
        query Bar {
          human(id: 4) {
            ...HumanFields2
          }
        }
        fragment HumanFields1 on Human {
          name
          ...HumanFields3
        }
        fragment HumanFields2 on Human {
          name
        }
        fragment HumanFields3 on Human {
          name
        }
        fragment Unused1 on Human {
          name
        }
        fragment Unused2 on Human {
          name
        }
        """,
        %{},
        [
          unused_fragment("Unused1", 21),
          unused_fragment("Unused2", 24),
        ]
      )
    end

    it "contains unknown fragments with ref cycle" do
      assert_fails_rule(@rule,
        """
        query Foo {
          human(id: 4) {
            ...HumanFields1
          }
        }
        query Bar {
          human(id: 4) {
            ...HumanFields2
          }
        }
        fragment HumanFields1 on Human {
          name
          ...HumanFields3
        }
        fragment HumanFields2 on Human {
          name
        }
        fragment HumanFields3 on Human {
          name
        }
        fragment Unused1 on Human {
          name
          ...Unused2
        }
        fragment Unused2 on Human {
          name
          ...Unused1
        }
        """,
        %{},
        [
          unused_fragment("Unused1", 21),
          unused_fragment("Unused2", 25),
        ]
      )
    end

    it "contains unknown and undef fragments" do
      assert_fails_rule(@rule,
        """
        query Foo {
          human(id: 4) {
            ...bar
          }
        }
        fragment foo on Human {
          name
        }
        """,
        %{},
        [
          unused_fragment("foo", 6),
        ]
      )
    end

  end

end
