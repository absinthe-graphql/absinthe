defmodule ValidationTest do
  use ExUnit.Case

  alias StarWars.Schema

  # Helper function to test a query and the expected response.
  defp validate(query) do
    source = %ExGraphQL.Language.Source{body: query, name: "StarWars.graphql"}
    document = ExGraphQL.parse!(source)
    ExGraphQL.Validation.validate(Schema.schema, document)
  end

  defp assert_valid(query) do
    assert :ok = validate(query)
  end

  defp assert_invalid(query) do
    assert {:error, _} = validate(query)
  end

  test "Validates a complex but valid query" do
    """
    query NestedQueryWithFragment {
      hero {
        ...NameAndAppearances
        friends {
          ...NameAndAppearances
          friends {
            ...NameAndAppearances
          }
        }
      }
    }

    fragment NameAndAppearances on Character {
      name
      appearsIn
    }
    """
    |> assert_valid
  end

  test "Notes that non-existent fields are invalid" do
    """
    query HeroSpaceshipQuery {
      hero {
        favoriteSpaceship
      }
    }
    """
    |> assert_invalid
  end

  test "Requires fields on objects" do
    """
    query HeroNoFieldsQuery {
      hero
    }
    """
    |> assert_invalid
  end

  test "Disallows fields on scalars" do
    """
    query HeroFieldsOnScalarQuery {
      hero {
        name {
          firstCharacterOfName
        }
      }
    }
    """
    |> assert_invalid
  end

  test "Disallows object fields on interfaces" do
    """
    query DroidFieldOnCharacter {
      hero {
        name
        primaryFunction
      }
    }
    """
    |> assert_invalid
  end

  test "Allows object fields in fragments" do
    """
    query DroidFieldInFragment {
      hero {
        name
        ...DroidFields
      }
    }

    fragment DroidFields on Droid {
      primaryFunction
    }
    """
    |> assert_valid
  end

  test "Allows object fields in inline fragments" do
    """
    query DroidFieldInFragment {
      hero {
        name
        ... on Droid {
          primaryFunction
        }
      }
    }
    """
    |> assert_valid
  end

end
