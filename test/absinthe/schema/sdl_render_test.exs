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
    - [ ] Remove macro based tests when SDL support matches
          - add default value to SDL test
  """

  defmodule SdlTestSchema do
    use Absinthe.Schema

    @sdl """
    schema {
      query: Query
    }

    directive @foo(name: String!) on OBJECT | SCALAR

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

    scalar SweetScalar

    type Query {
      echo(
        category: Category!

        "The number of times"
        times: Int
      ): [Category!]!
      posts: Post
      search(limit: Int, sort: SorterInput!): [SearchResult]
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

    interface Pet {
      name: String!
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
    {:ok, blueprint, _phases} = run(SdlTestSchema)

    rendered_sdl = Absinthe.Schema.Notation.SDL.Render.inspect(blueprint)

    assert rendered_sdl == SdlTestSchema.sdl()
  end

  defmodule ClassicTestSchema do
    use Absinthe.Schema

    query do
      field :echo, :string do
        arg :times, :integer, default_value: 10, description: "The number of times"
      end
    end
  end

  @expected_sdl """
  schema {
    query: RootQueryType
  }

  type RootQueryType {
    echo(
      "The number of times"
      times: Int = 10
    ): String
  }
  """
  test "Render SDL from blueprint defined with macros" do
    {:ok, blueprint, _phases} = run(ClassicTestSchema)

    rendered_sdl = Absinthe.Schema.Notation.SDL.Render.inspect(blueprint)

    assert rendered_sdl == @expected_sdl
  end

  def run(schema_module) do
    pipeline =
      schema_module
      |> Absinthe.Pipeline.for_schema()
      |> Absinthe.Pipeline.upto(Absinthe.Phase.Schema.Build)
      # NormalizeReferences replaces TypeReference structs that we need
      # with just atom identifiers
      #  * custom scalars
      #  * interface types
      |> Absinthe.Pipeline.without(Absinthe.Phase.Schema.NormalizeReferences)
      |> Absinthe.Pipeline.without(Absinthe.Phase.Schema.Validation.TypeReferencesExist)
      |> Absinthe.Pipeline.without(Absinthe.Phase.Schema.Validation.ObjectInterfacesMustBeValid)

    Absinthe.Pipeline.run(schema_module.__absinthe_blueprint__(), pipeline)
  end
end
