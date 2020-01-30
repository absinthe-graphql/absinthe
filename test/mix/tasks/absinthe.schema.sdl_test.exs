defmodule Mix.Tasks.Absinthe.Schema.SdlTest do
  use Absinthe.Case, async: true

  alias Mix.Tasks.Absinthe.Schema.Sdl, as: Task

  defmodule TestSchema do
    use Absinthe.Schema

    """
    schema {
      query: Query
    }

    type Query {
      helloWorld(name: String!): String
    }
    """
    |> import_sdl
  end

  @test_schema "Mix.Tasks.Absinthe.Schema.SdlTest.TestSchema"

  describe "absinthe.schema.sdl" do
    test "parses options" do
      argv = ["output.graphql", "--schema", @test_schema]

      opts = Task.parse_options(argv)

      assert opts.filename == "output.graphql"
      assert opts.schema == TestSchema
    end

    test "provides default options" do
      argv = ["--schema", @test_schema]

      opts = Task.parse_options(argv)

      assert opts.filename == "./schema.graphql"
      assert opts.schema == TestSchema
    end

    test "fails if no schema arg is provided" do
      argv = []
      catch_error(Task.parse_options(argv))
    end

    test "Generate schema" do
      argv = ["--schema", @test_schema]
      opts = Task.parse_options(argv)

      {:ok, schema} = Task.generate_schema(opts)
      assert schema =~ "helloWorld(name: String!): String"
    end
  end

  test "can parse schemas with directives having nested args" do
    defmodule SchemaWithDirectivesWithNestedArgs do
      use Absinthe.Schema

      defmodule Directives do
        use Absinthe.Schema.Prototype

        directive :some_directive do
          on [:field_definition]
        end
      end

      @prototype_schema Directives

      """
      type Widget {
        name: String @some_directive(a: { b: {} })
      }

      type Query {
        widgets: [Widget!]
      }
      """
      |> import_sdl
    end
  end
end
