defmodule Absinthe.Language.RenderTest do
  use ExUnit.Case, async: true

  describe "renders graphql" do
    test "for unnamed query" do
      assert_rendered("""
      {
        version
      }
      """)
    end

    test "for fragment typing" do
      assert_rendered("""
      query FragmentTyping {
        profiles(handles: ["zuck", "cocacola"]) {
          handle
          ...userFragment
          ...pageFragment
        }
      }

      fragment userFragment on User @defer {
        friends {
          count
        }
      }

      fragment pageFragment on Page {
        likers {
          count
        }
      }
      """)
    end

    test "for inline fragment with type query" do
      assert_rendered("""
      query inlineFragmentTyping {
        profiles(handles: ["zuck", "cocacola"]) {
          handle
          ... on User @onInlineFragment {
            friends {
              count
            }
          }
          ... on Page {
            likers {
              count
            }
          }
        }
      }
      """)
    end

    test "for inline fragments without type query" do
      assert_rendered("""
      query inlineFragmentNoType($expandedInfo: Boolean) {
        user(handle: "zuck") {
          id
          name
          ... @include(if: $expandedInfo) {
            firstName
            lastName
            birthday
          }
        }
      }
      """)
    end

    test "for block strings" do
      assert_rendered("""
      mutation {
        sendEmail(message: \"\"\"
          Hello,
            World!

          Yours,
            GraphQL.
        \"\"\")
      }
      """)
    end

    test "for null values" do
      assert_rendered("""
      query {
        field(arg: null)
        field
      }
      """)
    end

    test "for input objects" do
      assert_rendered("""
      query {
        nearestThing(location: { lon: 12.43, lat: -53.211 })
      }
      """)
    end

    test "for variables" do
      assert_rendered("""
      query ($id: ID, $mult: Int = 6, $list: [Int!]! = [1, 2], $customScalar: CustomScalar!) {
        times(base: 4, multiplier: $mult)
      }
      """)
    end

    test "for introspection query" do
      assert_rendered(
        Path.join(__DIR__, "../../../priv/graphql/introspection.graphql")
        |> File.read!()
      )
    end
  end

  defp assert_rendered(graphql) do
    {:ok, blueprint} = Absinthe.Phase.Parse.run(graphql, [])
    rendered_graphql = inspect(blueprint.input, pretty: true)

    assert graphql == rendered_graphql
  end
end
