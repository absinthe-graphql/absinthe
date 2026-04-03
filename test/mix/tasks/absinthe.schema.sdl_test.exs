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
      interfaceField: Being
    }

    interface Being {
      name: String
    }

    type Human implements Being {
      name: String
    }

    type Robot implements Being {
      name: String
    }
    """
    |> import_sdl

    def hydrate(%Absinthe.Blueprint.Schema.InterfaceTypeDefinition{}, _) do
      {:resolve_type, &__MODULE__.resolve_type/1}
    end

    def hydrate(_node, _ancestors), do: []

    def resolve_type(_), do: false
  end

  @test_schema "Mix.Tasks.Absinthe.Schema.SdlTest.TestSchema"

  defmodule TestModField do
    use Absinthe.Schema.Notation

    object :test_mod_helper do
      description "Simple Helper Object used to define blueprint fields"

      field :mod_field, :string do
        description "extra field added by schema modification"
      end
    end
  end

  defmodule TestModifier do
    alias Absinthe.{Phase, Pipeline, Blueprint}

    # Add this module to the pipeline of phases
    # to run on the schema
    def pipeline(pipeline) do
      Pipeline.insert_after(pipeline, Phase.Schema.TypeImports, __MODULE__)
    end

    # Here's the blueprint of the schema, let's do whatever we want with it.
    def run(blueprint = %Blueprint{}, _) do
      test_mod_types = Blueprint.types_by_name(TestModField)
      test_mod_fields = test_mod_types["TestModHelper"]

      mod_field = Blueprint.find_field(test_mod_fields, "mod_field")

      blueprint = Blueprint.add_field(blueprint, "Mod", mod_field)

      {:ok, blueprint}
    end
  end

  defmodule TestSchemaWithMods do
    use Absinthe.Schema

    @pipeline_modifier TestModifier

    query do
      field :hello_world, :mod do
        arg :name, non_null(:string)
      end

      field :interface_field, :being
    end

    object :mod do
    end

    interface :being do
      field :name, :string
      resolve_type(fn obj, _ -> obj.type end)
    end

    object :human do
      interface :being
      field :name, :string
    end

    object :robot do
      interface :being
      field :name, :string
    end
  end

  defmodule PersistentTermTestSchema do
    use Absinthe.Schema

    @schema_provider Absinthe.Schema.PersistentTerm

    query do
      field :item, :item
    end

    object :item do
      description "A Basic Type"
      field :id, :id
      field :name, :string
    end
  end

  defmodule DefaultValueTestSchema do
    use Absinthe.Schema

    enum :color do
      value :red
      value :green
      value :blue
    end

    enum :priority do
      value :high
      value :medium
      value :low
    end

    enum :status do
      value :active
      value :inactive
    end

    query do
      field :item, :string do
        arg :show, :boolean, default_value: true
      end

      field :search, :string do
        arg :filters, :filters, default_value: %{query: "mystring"}
      end

      field :enum_field, :string do
        arg :input, :enum_input
      end

      field :sorted_items, :string do
        arg :input, :sort_input
      end

      field :nested_field, :string do
        arg :input, :nested_input
      end

      field :list_field, :string do
        arg :input, :list_input
      end

      field :optional_field, :string do
        arg :input, :optional_input
      end
    end

    mutation do
      field :create_item, :string do
        arg :input, non_null(:test_input)
        arg :other, :string, default_value: "other"
      end
    end

    input_object :filters do
      field :query, :string
    end

    input_object :test_input do
      field :value, non_null(:string), default_value: "test"
    end

    input_object :enum_input do
      field :name, non_null(:string)
      field :color, :color, default_value: :red
    end

    input_object :sort_input do
      field :priority, :priority, default_value: :high
      field :include_archived, :boolean, default_value: false
    end

    input_object :nested_input do
      field :status, :status, default_value: :active
    end

    input_object :list_input do
      field :items, list_of(:string), default_value: ["test"]
      field :default_status, :status, default_value: :inactive
    end

    input_object :optional_input do
      field :optional_status, :status
      field :required_status, non_null(:status), default_value: :active
    end
  end

  @test_mod_schema "Mix.Tasks.Absinthe.Schema.SdlTest.TestSchemaWithMods"

  setup_all do
    shell = Mix.shell()
    Mix.shell(Mix.Shell.Quiet)
    on_exit(fn -> Mix.shell(shell) end)
  end

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

    test "Generate schema with modifier" do
      argv = ["--schema", @test_mod_schema]
      opts = Task.parse_options(argv)

      {:ok, schema} = Task.generate_schema(opts)

      assert schema =~ "type Mod {"
      assert schema =~ "modField: String"
      assert schema =~ "type Robot implements Being"
    end

    @tag :tmp_dir
    test "generates an SDL file", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "schema.sdl")

      argv = ["--schema", @test_schema, path]
      assert Task.run(argv)

      assert File.exists?(path)
    end

    @tag :tmp_dir
    test "generates an SDL file for a persistent term schema provider", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "schema.sdl")

      argv = ["--schema", "#{PersistentTermTestSchema}", path]
      assert Task.run(argv)

      assert File.exists?(path)
    end

    test "with default values including enums" do
      argv = ["output.graphql", "--schema", "#{DefaultValueTestSchema}"]
      opts = Task.parse_options(argv)

      {:ok, schema} = Task.generate_schema(opts)

      assert schema =~ "value: String! = \"test\""
      assert schema =~ "other: String = \"other\""
      assert schema =~ "show: Boolean = true"
      assert schema =~ "filters: Filters = {query: \"mystring\"}"
      assert schema =~ "input EnumInput {"
      assert schema =~ "color: Color = RED"
      assert schema =~ "input SortInput {"
      assert schema =~ "priority: Priority = HIGH"
      assert schema =~ "includeArchived: Boolean = false"
      assert schema =~ "input NestedInput {"
      assert schema =~ "status: Status = ACTIVE"
      assert schema =~ "input ListInput {"
      assert schema =~ ~s(items: [String] = ["test"])
      assert schema =~ "defaultStatus: Status = INACTIVE"
      assert schema =~ "input OptionalInput {"
      assert schema =~ "optionalStatus: Status"
      assert schema =~ "requiredStatus: Status! = ACTIVE"
    end
  end
end
