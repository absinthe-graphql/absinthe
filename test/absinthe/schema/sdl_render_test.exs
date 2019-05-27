defmodule SdlRenderTest do
  use ExUnit.Case

  defmodule TestSchema do
    use Absinthe.Schema

    @sdl """
    directive @foo(name: String!) on OBJECT | SCALAR

    type User {
      name: String!
    }

    scalar SweetScalar

    "Sort this thing"
    input SorterInput {
      "By this field"
      field: String!
    }

    "One or the other"
    union SearchResult = Post | User

    type Query {
      echo(
        category: Category!
        "The number of times"
        times: Int
      ): [Category!]!
      posts: Post
      search(limit: Int, sort: SorterInput!): [SearchResult]
    }

    \"""
    A submitted post
    Multiline description
    \"""
    type Post {
      old: String
      sweet: SweetScalar
      title: String!
    }

    "Simple description"
    enum Category {
      NEWS
      OPINION
    }
    """
    import_sdl @sdl
    def sdl, do: @sdl
  end

  @moduledoc """
  https://wehavefaces.net/graphql-shorthand-notation-cheatsheet-17cd715861b6
  https://github.com/graphql/graphql-js/blob/master/src/utilities/schemaPrinter.js

  issues:
    - schema definition order is not respected?

  todo:
    - [ ] interface & implements
    - [x] custom scalar
    - [x] directives
    - [x] inspect based arg lines

  todo after fixed:
    - [ ] @deprecated
            @deprecated(reason: "Reason")
    - [ ] schema block
            https://github.com/absinthe-graphql/absinthe/pull/735
    - [ ] default values (scalar and complex?)
            `foo: Int = 10`
  """

  test "Algebra exploration" do
    {:ok, %{data: data}} = Absinthe.Schema.introspect(TestSchema)

    rendered = Absinthe.Schema.Notation.SDL.Render.from_introspection(data)

    IO.puts("")
    IO.puts("-----------")
    IO.puts(rendered)
    IO.puts("-----------")

    assert rendered == TestSchema.sdl()
  end
end
