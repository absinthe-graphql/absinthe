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

  describe "renders sdl" do
    test "for a type" do
      assert_rendered("""
      type Person implements Entity {
        name: String!
        baz: Int
      }
      """)
    end

    test "for an interface" do
      assert_rendered("""
      interface Entity implements Node {
        name: String!
      }
      """)
    end

    test "for an input" do
      assert_rendered("""
      "Description for Profile"
      input Profile {
        "Description for name"
        name: String!
      }
      """)
    end

    test "for a union with types" do
      assert_rendered("""
      union Foo = Bar | Baz
      """)
    end

    test "for a union without types" do
      assert_rendered("""
      union Foo
      """)
    end

    test "for a scalar" do
      assert_rendered("""
      scalar MyGreatScalar
      """)
    end

    test "for a directive" do
      assert_rendered("""
      directive @foo(name: String!) on OBJECT | SCALAR
      """)
    end

    test "for a type extension" do
      assert_rendered("""
      extend union Direction = North | South
      """)
    end

    test "for a schema declaration" do
      assert_rendered("""
      schema {
        query: Query
      }
      """)
    end
  end

  @sdl """
  "Schema description"
  schema {
    query: Query
  }

  directive @foo(name: String!) repeatable on OBJECT | SCALAR

  interface Animal {
    legCount: Int!
  }

  \"""
  A submitted post
  Multiline description
  \"""
  type Post {
    old: String @deprecated(reason: \"""
      It's old
      Really old
    \""")

    sweet: SweetScalar

    "Something"
    title: String!
  }

  input ComplexInput {
    foo: String
  }

  scalar SweetScalar

  type Query {
    echo(
      category: Category!

      "The number of times"
      times: Int = 10
    ): [Category!]!
    posts: Post
    search(limit: Int, sort: SorterInput!): [SearchResult]
    defaultBooleanArg(boolean: Boolean = false): String
    defaultInputArg(input: ComplexInput = { foo: "bar" }): String
    defaultListArg(things: [String] = ["ThisThing"]): [String]
    defaultEnumArg(category: Category = NEWS): Category
    defaultNullStringArg(name: String = null): String
    animal: Animal
  }

  type Dog implements Pet & Animal {
    legCount: Int!
    name: String!
  }

  "Simple description"
  enum Category {
    "Just the facts"
    NEWS

    \"""
    What some rando thinks

    Take with a grain of salt
    \"""
    OPINION

    CLASSIFIED
  }

  interface Pet implements Animal {
    name: String!
    legCount: Int!
  }

  "One or the other"
  union SearchResult = Post | User

  "Sort this thing"
  input SorterInput {
    "By this field"
    field: String!
  }

  type User {
    name: String!
  }

  extend type User @feature {
    nickname: String
  }
  """
  test "renders SDL schema" do
    assert_rendered(@sdl)
  end

  defp assert_rendered(graphql) do
    {:ok, blueprint} = Absinthe.Phase.Parse.run(graphql, [])
    rendered_graphql = inspect(blueprint.input, pretty: true)

    assert graphql == rendered_graphql
  end
end
