defmodule Absinthe.Schema.SdlRenderTest do
  use ExUnit.Case, async: true

  defmodule SdlTestSchema do
    use Absinthe.Schema

    alias Absinthe.Blueprint.Schema

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
      defaultInputArg(input: ComplexInput = {foo: "bar"}): String
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
    """
    import_sdl @sdl
    def sdl, do: @sdl

    def hydrate(%Schema.InterfaceTypeDefinition{identifier: :animal}, _) do
      {:resolve_type, &__MODULE__.resolve_type/1}
    end

    def hydrate(%{identifier: :pet}, _) do
      {:resolve_type, &__MODULE__.resolve_type/1}
    end

    def hydrate(_node, _ancestors), do: []

    def resolve_type(_), do: false
  end

  test "Render SDL from blueprint defined with SDL" do
    assert Absinthe.Schema.to_sdl(SdlTestSchema) ==
             SdlTestSchema.sdl()
  end

  describe "Render SDL" do
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

    test "for a schema declaration" do
      assert_rendered("""
      schema {
        query: Query
      }
      """)
    end

    test "for a type with directive input object" do
      assert_rendered("""
      type TypeWithDirective {
        some: String @additionalInfo(input: {enabled: true, description: "Some description"})
      }
      """)
    end
  end

  defp assert_rendered(sdl) do
    rendered_sdl =
      with {:ok, %{input: doc}} <- Absinthe.Phase.Parse.run(sdl),
           %Absinthe.Language.Document{definitions: [node]} <- doc,
           blueprint = Absinthe.Blueprint.Draft.convert(node, doc) do
        Inspect.inspect(blueprint, %Inspect.Opts{pretty: true})
      end

    assert sdl == rendered_sdl
  end

  defmodule SchemaPrototypeTest do
    use Absinthe.Schema.Prototype

    input_object :info do
      field :enabled, :boolean
      field :description, :string
    end

    directive :additional_info do
      arg :input, :info
      on [:field_definition]
    end
  end

  defmodule MacroTestSchema do
    use Absinthe.Schema
    @prototype_schema SchemaPrototypeTest

    query do
      description "Escaped\t\"descrição/description\""

      field :echo, :string do
        arg :times, :integer, default_value: 10, description: "The number of times"
        arg :time_interval, :integer
      end

      field :search, :search_result

      field :documented_field, :string do
        directive :additional_info, input: %{enabled: true, description: "Some description"}
      end
    end

    directive :foo do
      arg :baz, :string
      on :field
    end

    enum :order_status do
      value :delivered
      value :processing
      value :picking
    end

    enum :status, values: [:one, :two, :three]

    object :order do
      field :id, :id
      field :name, :string
      field :status, :order_status
      field :other_status, :status
      import_fields :imported_fields
    end

    object :category do
      field :name, :string
    end

    object :imported_fields do
      field :imported, non_null(:boolean)
    end

    union :search_result do
      types [:order, :category]
    end
  end

  test "Render SDL from blueprint defined with macros" do
    assert Absinthe.Schema.to_sdl(MacroTestSchema) ==
             """
             schema {
               query: RootQueryType
             }

             directive @foo(baz: String) on FIELD

             \"Escaped\\t\\\"descrição\\/description\\\"\"
             type RootQueryType {
               echo(
                 \"The number of times\"
                 times: Int

                 timeInterval: Int
               ): String
               search: SearchResult
               documentedField: String @additionalInfo(input: {enabled: true, description: \"Some description\"})
             }

             enum OrderStatus {
               DELIVERED
               PROCESSING
               PICKING
             }

             enum Status {
               ONE
               TWO
               THREE
             }

             type Order {
               imported: Boolean!
               id: ID
               name: String
               status: OrderStatus
               otherStatus: Status
             }

             type Category {
               name: String
             }

             union SearchResult = Order | Category
             """
  end

  defmodule TestModifier do
    def pipeline(pipeline, opts) do
      send(self(), type: :module, opts: opts)
      pipeline
    end
  end

  defmodule ModifiedTestSchema do
    use Absinthe.Schema

    def custom_pipeline(pipeline, opts) do
      send(self(), type: :function, opts: opts)
      pipeline
    end

    @pipeline_modifier TestModifier
    @pipeline_modifier {__MODULE__, :custom_pipeline}

    @sdl """
    type Query {
      echo: String
    }
    """
    import_sdl @sdl
  end

  test "Render SDL takes opts" do
    Absinthe.Schema.to_sdl(ModifiedTestSchema, sdl_render: true)
    assert_received type: :function, opts: [sdl_render: true]
    assert_received type: :module, opts: [sdl_render: true]
  end
end
