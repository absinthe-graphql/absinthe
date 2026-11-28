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

  defmodule DeprecatedSchema do
    use Absinthe.Schema

    query do
      field :search, :string do
        arg :term, :string
        arg :legacy_term, :string, deprecate: "Use term"
        arg :filter, :search_filter
      end

      field :legacy_search, :string, deprecate: "Use search"
    end

    input_object :search_filter do
      field :kind, :string
      field :legacy_kind, :string, deprecate: "Use kind"
      field :mode, :search_mode
    end

    enum :search_mode do
      value :exact
      value :legacy_fuzzy, deprecate: "Use exact"
    end
  end

  defmodule TestEncoder do
    def encode!(_map, opts) do
      pretty_flag = Keyword.get(opts, :pretty, false)
      pretty_string = if pretty_flag, do: "pretty", else: "ugly"
      "test-encoder-#{pretty_string}"
    end
  end

  defmodule PassthroughEncoder do
    def encode!(map, _opts), do: map
  end

  @test_schema "Mix.Tasks.Absinthe.Schema.JsonTest.TestSchema"
  @test_encoder "Mix.Tasks.Absinthe.Schema.JsonTest.TestEncoder"
  @passthrough_encoder "Mix.Tasks.Absinthe.Schema.JsonTest.PassthroughEncoder"
  @deprecated_schema "Mix.Tasks.Absinthe.Schema.JsonTest.DeprecatedSchema"

  setup_all do
    shell = Mix.shell()
    Mix.shell(Mix.Shell.Quiet)
    on_exit(fn -> Mix.shell(shell) end)
  end

  describe "absinthe.schema.json" do
    test "parses options" do
      argv = [
        "output.json",
        "--schema",
        @test_schema,
        "--json-codec",
        @test_encoder,
        "--pretty",
        "--include-deprecated"
      ]

      opts = Task.parse_options(argv)

      assert opts.filename == "output.json"
      assert opts.json_codec == TestEncoder
      assert opts.pretty == true
      assert opts.schema == TestSchema
      assert opts.include_deprecated == true
    end

    test "provides default options" do
      argv = ["--schema", @test_schema]

      opts = Task.parse_options(argv)

      assert opts.filename == "./schema.json"
      assert opts.json_codec == Jason
      assert opts.pretty == false
      assert opts.schema == TestSchema
      assert opts.include_deprecated == nil
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

    test "keeps the default deprecation behaviour without --include-deprecated" do
      types = generate_deprecated([])

      assert names(types, "RootQueryType", "fields") == ["legacySearch", "search"]
      assert names(types, "SearchMode", "enumValues") == ["EXACT", "LEGACY_FUZZY"]
      assert search_arg_names(types) == ["filter", "term"]
      assert names(types, "SearchFilter", "inputFields") == ["kind", "mode"]
    end

    test "includes everything deprecated with --include-deprecated" do
      types = generate_deprecated(["--include-deprecated"])

      assert names(types, "RootQueryType", "fields") == ["legacySearch", "search"]
      assert names(types, "SearchMode", "enumValues") == ["EXACT", "LEGACY_FUZZY"]
      assert search_arg_names(types) == ["filter", "legacyTerm", "term"]
      assert names(types, "SearchFilter", "inputFields") == ["kind", "legacyKind", "mode"]

      assert %{"isDeprecated" => true, "deprecationReason" => "Use term"} =
               types |> search_args() |> Enum.find(&(&1["name"] == "legacyTerm"))

      assert %{"isDeprecated" => true, "deprecationReason" => "Use kind"} =
               types
               |> find_type("SearchFilter")
               |> Map.fetch!("inputFields")
               |> Enum.find(&(&1["name"] == "legacyKind"))
    end

    test "excludes everything deprecated with --no-include-deprecated" do
      types = generate_deprecated(["--no-include-deprecated"])

      assert names(types, "RootQueryType", "fields") == ["search"]
      assert names(types, "SearchMode", "enumValues") == ["EXACT"]
      assert search_arg_names(types) == ["filter", "term"]
      assert names(types, "SearchFilter", "inputFields") == ["kind", "mode"]
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

  defp generate_deprecated(argv) do
    opts =
      Task.parse_options(
        ["--schema", @deprecated_schema, "--json-codec", @passthrough_encoder] ++ argv
      )

    {:ok, %{data: %{"__schema" => %{"types" => types}}}} = Task.generate_schema(opts)
    types
  end

  defp find_type(types, name), do: Enum.find(types, &(&1["name"] == name))

  defp names(types, type_name, key) do
    types |> find_type(type_name) |> Map.fetch!(key) |> Enum.map(& &1["name"]) |> Enum.sort()
  end

  defp search_args(types) do
    types
    |> find_type("RootQueryType")
    |> Map.fetch!("fields")
    |> Enum.find(&(&1["name"] == "search"))
    |> Map.fetch!("args")
  end

  defp search_arg_names(types),
    do: types |> search_args() |> Enum.map(& &1["name"]) |> Enum.sort()
end
