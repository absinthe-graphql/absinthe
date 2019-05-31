defmodule SdlRenderTest do
  use ExUnit.Case

  @moduledoc """
  https://wehavefaces.net/graphql-shorthand-notation-cheatsheet-17cd715861b6
  https://github.com/graphql/graphql-js/blob/master/src/utilities/schemaPrinter.js

  issues:
    - schema definition order is not respected?

  todo:
    - [x] interface & implements
    - [x] custom scalar
    - [x] directives
    - [x] inspect based arg lines
    - [x] default values (scalar)
    - [x] default values (complex)
    - [x] deprecated & reason
    - [ ] schema block
            https://github.com/absinthe-graphql/absinthe/pull/735

  sdl parsing:
    - default values
    - deprecated
    - schema block
  """

  defmodule SdlTestSchema do
    use Absinthe.Schema

    @sdl """
    directive @foo(name: String!) on OBJECT | SCALAR

    "Simple description"
    enum Category {
      NEWS
      OPINION
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
    """
    import_sdl @sdl
    def sdl, do: @sdl
  end

  test "Render SDL from schema defined with SDL" do
    {:ok, %{data: data}} = Absinthe.Schema.introspect(SdlTestSchema)
    rendered_sdl = Absinthe.Schema.Notation.SDL.Render.from_introspection(data)
    assert rendered_sdl == SdlTestSchema.sdl()
  end

  defmodule ClassicTestSchema do
    use Absinthe.Schema

    directive :foo do
      arg :name, non_null(:string)
      on [:object, :scalar]
    end

    interface :animal do
      field :legs, non_null(:integer)

      resolve_type fn
        %{name: _} -> :dog
        %{web_complexity: _} -> :spider
      end
    end

    interface :pet do
      field :name, non_null(:string)

      resolve_type fn
        %{name: _} -> :dog
      end
    end

    object :dog do
      interfaces [:animal, :pet]
      field :legs, non_null(:integer)

      field :name, non_null(:string) do
        deprecate("""
        Don't use This
        """)
      end
    end

    object :spider do
      interfaces [:animal]
      field :legs, non_null(:integer)

      field :web_complexity, non_null(:float) do
        deprecate("""
        Definately
        Don't use This
        """)
      end
    end

    query do
      field :pets, list_of(:pet)
      field :animals, list_of(:animal)

      field :echo, :integer do
        arg :n, non_null(:integer), default_value: 10, description: "Echo it back"
      end
    end
  end

  @expected_sdl """
  schema {
    query: RootQueryType
  }

  directive @foo(name: String!) on OBJECT | SCALAR

  interface Animal {
    legs: Int!
  }

  type Dog implements Pet, Animal {
    legs: Int!
    name: String! @deprecated(reason: "Don't use This")
  }

  interface Pet {
    name: String!
  }

  type RootQueryType {
    animals: [Animal]
    echo(
      "Echo it back"
      n: Int! = 10
    ): Int
    pets: [Pet]
  }

  type Spider implements Animal {
    legs: Int!
    webComplexity: Float! @deprecated(reason: \"""
      Definately
      Don't use This
    \""")
  }
  """
  test "Render SDL from schema defined with macros" do
    {:ok, %{data: data}} = Absinthe.Schema.introspect(ClassicTestSchema)
    rendered_sdl = Absinthe.Schema.Notation.SDL.Render.from_introspection(data)
    assert rendered_sdl == @expected_sdl
  end

  test "Render SDL from blueprint" do
    rendered_sdl =
      Absinthe.Schema.Notation.SDL.Render.from_blueprint(
        ClassicTestSchema.__absinthe_blueprint__()
      )

    assert rendered_sdl == @expected_sdl
  end
end
