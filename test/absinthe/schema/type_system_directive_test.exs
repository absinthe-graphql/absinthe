defmodule Absinthe.Schema.TypeSystemDirectiveTest do
  use ExUnit.Case, async: true

  defmodule WithTypeSystemDirective do
    use Absinthe.Schema.Prototype

    input_object :complex do
      field :str, :string
    end

    directive :external do
      on [:field_definition]
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

    directive :camel_case_me do
      on [:field_definition]
    end
  end

  defmodule TypeSystemDirectivesSdlSchema do
    use Absinthe.Schema

    @prototype_schema WithTypeSystemDirective

    @sdl """
    schema @feature(name: ":schema") {
      query: Query
    }

    interface Animal @feature(name: ":interface") {
      legCount: Int! @feature(name: \"""
        Multiline here?
        Second line
      \""")
    }

    input SearchFilter @feature(name: ":input_object") {
      query: String = "default" @feature(name: ":input_field_definition")
    }

    type Post @feature(name: ":object", number: 3, complex: {str: "foo"}) {
      name: String @deprecated(reason: "Bye") @external
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
      THE_OTHER @deprecated(reason: "It's old")
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

  defmodule TypeSystemDirectivesMacroSchema do
    use Absinthe.Schema

    @prototype_schema WithTypeSystemDirective

    schema do
      directive :feature, name: ":schema"
      field :query, :query
    end

    query do
      field :post, :post do
        directive :feature, name: ":field_definition"
      end

      field :sweet, :sweet_scalar, directives: [:camel_case_me]
      field :which, :category
      field :pet, :dog

      field :search, :search_result do
        arg :filter, :search_filter, directives: [{:feature, name: ":argument_definition"}]
        directive :feature, name: ":argument_definition"
      end
    end

    object :post do
      directive :feature, name: ":object", number: 3

      field :name, :string do
        deprecate "Bye"
      end
    end

    scalar :sweet_scalar do
      directive :feature, name: ":scalar"
      parse &Function.identity/1
      serialize &Function.identity/1
    end

    enum :category do
      directive :feature, name: ":enum"
      value :this
      value :that, directives: [feature: [name: ":enum_value"]]
      value :the_other, directives: [deprecated: [reason: "It's old"]]
    end

    interface :animal do
      directive :feature, name: ":interface"

      field :leg_count, non_null(:integer) do
        directive :feature,
          name: """
          Multiline here?
          Second line
          """
      end
    end

    object :dog do
      is_type_of fn _ -> true end
      interface :animal
      field :leg_count, non_null(:integer)
      field :name, non_null(:string), directives: [:external]
    end

    input_object :search_filter do
      directive :feature, name: ":input_object"

      field :query, :string, default_value: "default" do
        directive :feature, name: ":input_field_definition"
      end
    end

    union :search_result do
      directive :feature, name: ":union"
      types [:dog, :post]

      resolve_type fn %{type: type}, _ -> type end
    end
  end

  describe "with SDL schema" do
    test "Render SDL with Type System Directives applied" do
      assert Absinthe.Schema.to_sdl(TypeSystemDirectivesSdlSchema) ==
               TypeSystemDirectivesSdlSchema.sdl()
    end
  end

  @macro_schema_sdl """
  schema @feature(name: \":schema\") {
    query: RootQueryType
  }

  type RootQueryType {
    post: Post @feature(name: \":field_definition\")
    sweet: SweetScalar @camelCaseMe
    which: Category
    pet: Dog
    search(filter: SearchFilter @feature(name: \":argument_definition\")): SearchResult @feature(name: \":argument_definition\")
  }

  type Post @feature(name: \":object\", number: 3) {
    name: String @deprecated(reason: \"Bye\")
  }

  scalar SweetScalar @feature(name: \":scalar\")

  enum Category @feature(name: \":enum\") {
    THIS
    THAT @feature(name: \":enum_value\")
    THE_OTHER @deprecated(reason: \"It's old\")
  }

  interface Animal @feature(name: \":interface\") {
    legCount: Int! @feature(name: \"\"\"
      Multiline here?
      Second line
    \"\"\")
  }

  type Dog implements Animal {
    legCount: Int!
    name: String! @external
  }

  input SearchFilter @feature(name: \":input_object\") {
    query: String @feature(name: \":input_field_definition\")
  }

  union SearchResult @feature(name: \":union\") = Dog | Post
  """
  describe "with macro schema" do
    test "Render SDL with Type System Directives applied" do
      assert Absinthe.Schema.to_sdl(TypeSystemDirectivesMacroSchema) ==
               @macro_schema_sdl
    end
  end
end
