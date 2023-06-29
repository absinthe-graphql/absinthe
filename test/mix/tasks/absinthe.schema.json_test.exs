defmodule Mix.Tasks.Absinthe.Schema.JsonTest do
  use Absinthe.Case, async: true

  alias Mix.Tasks.Absinthe.Schema.Json, as: Task

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      field :item, :item
    end

    object :item do
      description "A Basic Type"
      field :id, :id
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

  defmodule TestEncoder do
    def encode!(_map, opts) do
      pretty_flag = Keyword.get(opts, :pretty, false)
      pretty_string = if pretty_flag, do: "pretty", else: "ugly"
      "test-encoder-#{pretty_string}"
    end
  end

  @test_schema "Mix.Tasks.Absinthe.Schema.JsonTest.TestSchema"
  @test_encoder "Mix.Tasks.Absinthe.Schema.JsonTest.TestEncoder"

  setup_all do
    shell = Mix.shell()
    Mix.shell(Mix.Shell.Quiet)
    on_exit(fn -> Mix.shell(shell) end)
  end

  describe "absinthe.schema.json" do
    test "parses options" do
      argv = ["output.json", "--schema", @test_schema, "--json-codec", @test_encoder, "--pretty"]

      opts = Task.parse_options(argv)

      assert opts.filename == "output.json"
      assert opts.json_codec == TestEncoder
      assert opts.pretty == true
      assert opts.schema == TestSchema
    end

    test "provides default options" do
      argv = ["--schema", @test_schema]

      opts = Task.parse_options(argv)

      assert opts.filename == "./schema.json"
      assert opts.json_codec == Jason
      assert opts.pretty == false
      assert opts.schema == TestSchema
    end

    test "fails if no schema arg is provided" do
      argv = []
      catch_error(Task.parse_options(argv))
    end

    test "fails if codec hasn't been loaded" do
      argv = ["--schema", @test_schema, "--json-codec", "UnloadedCodec"]
      opts = Task.parse_options(argv)
      catch_error(Task.generate_schema(opts))
    end

    test "can use a custom codec" do
      argv = ["--schema", @test_schema, "--json-codec", @test_encoder, "--pretty"]

      opts = Task.parse_options(argv)
      {:ok, pretty_content} = Task.generate_schema(opts)
      {:ok, ugly_content} = Task.generate_schema(%{opts | pretty: false})

      assert pretty_content == "test-encoder-pretty"
      assert ugly_content == "test-encoder-ugly"
    end

    @tag :tmp_dir
    test "generates a JSON file", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "schema.json")

      argv = ["--schema", @test_schema, "--json-codec", @test_encoder, path]
      assert Task.run(argv)

      assert File.exists?(path)
    end

    @tag :tmp_dir
    test "generates a JSON file for a persistent term schema provider", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "schema.json")

      argv = ["--schema", "#{PersistentTermTestSchema}", "--json-codec", @test_encoder, path]
      assert Task.run(argv)

      assert File.exists?(path)
    end
  end
end
