defmodule Absinthe.Phase.Document.Validation.NoUnusedFragmentsTest do
  @phase Absinthe.Phase.Document.Validation.NoUnusedFragments

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp unused_fragment(name, line) do
    bad_value(
      Blueprint.Document.Fragment.Named,
      @phase.error_message(name),
      line,
      name: name
    )
  end

  describe "Validate: No unused fragments" do
    test "all fragment names are used" do
      assert_passes_validation(
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
        []
      )
    end

    test "all fragment names are used by multiple operations" do
      assert_passes_validation(
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
        []
      )
    end

    test "contains unknown fragments" do
      assert_fails_validation(
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
        [],
        [
          unused_fragment("Unused1", 21),
          unused_fragment("Unused2", 24)
        ]
      )
    end

    test "contains unknown fragments with ref cycle" do
      assert_fails_validation(
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
        [],
        [
          unused_fragment("Unused1", 21),
          unused_fragment("Unused2", 25)
        ]
      )
    end

    test "contains unknown and undef fragments" do
      assert_fails_validation(
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
        [],
        [
          unused_fragment("foo", 6)
        ]
      )
    end
  end
end
