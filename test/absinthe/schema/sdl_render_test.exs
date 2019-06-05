defmodule SdlRenderTest do
  use ExUnit.Case

  @moduledoc """
  https://wehavefaces.net/graphql-shorthand-notation-cheatsheet-17cd715861b6
  https://github.com/graphql/graphql-js/blob/master/src/utilities/schemaPrinter.js

  issues:
    - schema definition order is not respected?

  TODO:
    - [-] `Inspect` protocol for Blueprint structs!!!!!
           - for all structs
           - return docs, not string?
    - [X] Remove from_introspection
    - [ ] Remove macro based tests when SDL support matches
          - add default value to SDL test
          - add deprecated & reason to SDL test
  """

  defmodule SdlTestSchema do
    use Absinthe.Schema

    @sdl """
    schema {
      query: Query
    }

    directive @foo(name: String!) on OBJECT | SCALAR

    "Simple description"
    enum Category {
      "Just the facts"
      NEWS
      OPINION
      CLASSIFIED
    }

    \"""
    A submitted post
    Multiline description
    \"""
    type Post {
      old: String
      sweet: SweetScalar
      "Something"
      title: String!
    }

    type Query {
      echo(
        category: Category!
        "The number of times"
        times: Int
      ): [Category!]!
      posts: Post
      search(limit: Int, sort: SorterInput!): [SearchResult]
    }

    "One or the other"
    union SearchResult = Post | User

    "Sort this thing"
    input SorterInput {
      "By this field"
      field: String!
    }

    scalar SweetScalar

    type User {
      name: String!
    }

    type Dog implements Pet, Animal {
      legCount: Int!
      name: String!
    }

    interface Pet {
      name: String!
    }

    interface Animal {
      legCount: Int!
    }
    """
    import_sdl @sdl
    def sdl, do: @sdl

    def hydrate(%{identifier: :animal}, _) do
      {:resolve_type, &__MODULE__.resolve_type/1}
    end

    def hydrate(%{identifier: :pet}, _) do
      {:resolve_type, &__MODULE__.resolve_type/1}
    end

    def hydrate(_node, _ancestors), do: []
  end

  test "Render SDL from blueprint defined with SDL" do
    pipeline = [
      Absinthe.Phase.Schema.Debugger
    ]

    {:ok, blueprint, _phases} =
      Absinthe.Pipeline.run(SdlTestSchema.__absinthe_blueprint__(), pipeline)

    rendered_sdl = inspect(blueprint, pretty: true)

    assert rendered_sdl == SdlTestSchema.sdl()
  end

  defmodule ClassicTestSchema do
    use Absinthe.Schema

    @desc "Simple description"
    enum :category do
      value :opinion,
        deprecate: """
        Definately
        Don't use This
        """

      value :news
      value :classified, deprecate: "Craigslist"
    end

    query do
      field :echo, non_null(list_of(non_null(:category))) do
        deprecate "Don't use this"
        arg :times, :integer, default_value: 10, description: "The number of times"
        arg :category, non_null(:category)
      end
    end
  end

  @expected_sdl """
  schema {
    query: RootQueryType
  }

  type RootQueryType {
    echo(

      category: Category!
      "The number of times"
      times: Int = 10
    ): [Category!]! @deprecated(reason: "Don't use this")
  }

  "Simple description"
  enum Category {
    CLASSIFIED @deprecated(reason: "Craigslist")
    NEWS
    OPINION @deprecated(reason: \"""
      Definately
      Don't use This
    \""")
  }
  """
  test "Render SDL from blueprint defined with macros" do
    pipeline = [
      Absinthe.Phase.Schema.Debugger
    ]

    {:ok, blueprint, _phases} =
      Absinthe.Pipeline.run(ClassicTestSchema.__absinthe_blueprint__(), pipeline)

    rendered_sdl = inspect(blueprint, pretty: true)

    assert rendered_sdl == @expected_sdl

    [%{type_definitions: type_definitions}] = blueprint.schema_definitions
    category_type = Enum.find(type_definitions, &(&1.identifier == :category))

    expected_category_sdl = """
    "Simple description"
    enum Category {
      CLASSIFIED @deprecated(reason: "Craigslist")
      NEWS
      OPINION @deprecated(reason: \"""
        Definately
        Don't use This
      \""")
    }
    """

    rendered_category_sdl = inspect(category_type, pretty: true)
    assert rendered_category_sdl == expected_category_sdl
  end
end
