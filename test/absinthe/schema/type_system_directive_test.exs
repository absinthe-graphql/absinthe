defmodule TypeSystemDirectiveTest do
  use ExUnit.Case

  defmodule WithTypeSystemDirective do
    use Absinthe.Schema.Prototype

    input_object :complex do
      field :str, :string
    end

    directive :feature do
      arg :name, non_null(:string)
      arg :number, :integer
      arg :complex, :complex
      on [:object]
    end
  end

  defmodule SdlTestSchema do
    use Absinthe.Schema

    alias Absinthe.Blueprint.Schema

    @prototype_schema WithTypeSystemDirective

    @sdl """
    schema {
      query: Query
    }

    type Post @feature(name: "BAR", number: 3, complex: {str: "foo"}) {
      name: String @deprecated(reason: "Bye")
    }

    type Query {
      post: Post
    }
    """
    import_sdl @sdl
    def sdl, do: @sdl

    def hydrate(_node, _ancestors), do: []
  end

  test "Render SDL from blueprint defined with SDL" do
    assert Absinthe.Schema.to_sdl(SdlTestSchema) ==
             SdlTestSchema.sdl()
  end
end
