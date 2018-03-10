defmodule Absinthe.Phase.Document.Validation.KnownFragmentNamesTest do
  @phase Absinthe.Phase.Document.Validation.KnownFragmentNames

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp undefined_fragment(name, line) do
    bad_value(
      Blueprint.Document.Fragment.Spread,
      ~s(Unknown fragment "#{name}"),
      line,
      name: name
    )
  end

  describe "Validate: Known fragment names" do
    test "known fragment names are valid" do
      assert_passes_validation(
        """
        {
          human(id: 4) {
            ... HumanFields1
            ... on Human {
              ... HumanFields2
            }
            ... {
              name
            }
          }
        }
        fragment HumanFields1 on Human {
          name
          ... HumanFields3
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

    test "unknown fragment names are invalid" do
      assert_fails_validation(
        """
        {
          human(id: 4) {
            ...UnknownFragment1
            ... on Human {
              ...UnknownFragment2
            }
          }
        }
        fragment HumanFields on Human {
          name
          ...UnknownFragment3
        }
        """,
        [],
        [
          undefined_fragment("UnknownFragment1", 3),
          undefined_fragment("UnknownFragment2", 5),
          undefined_fragment("UnknownFragment3", 11)
        ]
      )
    end
  end
end
