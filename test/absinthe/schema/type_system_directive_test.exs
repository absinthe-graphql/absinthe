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

      repeatable true

      on [
        :schema,
        :scalar,
        :object,
        :field_definition,
        :argument_definition,
        :interface,
        :union,
        :enum,
        :enum_value,
        :input_object,
        :input_field_definition
      ]
    end
  end

  defmodule SdlTestSchema do
    use Absinthe.Schema

    @prototype_schema WithTypeSystemDirective

    @sdl """
    schema {
      query: Query
    }

    interface Animal @feature(name: ":interface") {
      legCount: Int!
    }

    input SearchFilter @feature(name: ":input_object") {
      query: String = "default" @feature(name: ":input_field_definition")
    }

    type Post @feature(name: ":object", number: 3, complex: {str: "foo"}) {
      name: String @deprecated(reason: "Bye")
    }

    scalar SweetScalar @feature(name: ":scalar")

    type Query {
      post: Post @feature(name: ":field_definition")
      sweet: SweetScalar
      pet: Dog
      which: Category
      search(filter: SearchFilter @feature(name: ":argument_definition")): SearchResult
    }

    type Dog implements Animal {
      legCount: Int!
      name: String!
    }

    enum Category @feature(name: ":enum") {
      THIS
      THAT @feature(name: ":enum_value")
    }

    union SearchResult @feature(name: ":union") = Dog | Post
    """
    import_sdl @sdl
    def sdl, do: @sdl

    def hydrate(%{identifier: :animal}, _) do
      {:resolve_type, &__MODULE__.resolve_type/1}
    end

    def hydrate(_node, _ancestors), do: []

    def resolve_type(_), do: false
  end

  test "Render SDL from blueprint defined with SDL" do
    assert Absinthe.Schema.to_sdl(SdlTestSchema) ==
             SdlTestSchema.sdl()
  end
end
