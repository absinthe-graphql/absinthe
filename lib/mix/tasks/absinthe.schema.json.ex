defmodule Mix.Tasks.Absinthe.Schema.Json do
  require Logger
  use Mix.Task
  import Mix.Generator

  @shortdoc "Generate a schema.json file for an Absinthe schema"

  @default_filename "./schema.json"
  @default_codec_name "Jason"

  @moduledoc """
  Generate a schema.json file

  ## Usage

      absinthe.schema.json [FILENAME] [OPTIONS]

  ## Options

      --schema The schema. Default: As configured for `:absinthe` `:schema`
      --json-codec Sets JSON Codec. Default: #{@default_codec_name}
      --pretty Whether to pretty-print. Default: false

  ## Examples

  Write to default path `#{@default_filename}` using the `:schema` configured for
  the `:absinthe` application and the default `#{@default_codec_name}` JSON codec:

      $ mix absinthe.schema.json

  Write to default path `#{@default_filename}` using the `MySchema` schema and
  the default `#{@default_codec_name}` JSON codec.

      $ mix absinthe.schema.json --schema MySchema

  Write to path `/path/to/schema.json` using the `MySchema` schema, using the
  default `#{@default_codec_name}` JSON codec, and pretty-printing:

      $ mix absinthe.schema.json --schema MySchema --pretty /path/to/schema.json

  Write to default path `#{@default_filename}` using the `MySchema` schema and
  a custom JSON codec, `MyCodec`:

      $ mix absinthe.schema.json --schema MySchema --json-codec MyCodec

  """

  @introspection_graphql Path.join([:code.priv_dir(:absinthe), "graphql", "introspection.graphql"])

  defmodule Options do
    defstruct filename: nil, schema: nil, json_codec: nil, pretty: false

    @type t() :: %__MODULE__{
            filename: String.t(),
            schema: module(),
            json_codec: module(),
            pretty: boolean()
          }
  end

  def run(argv) do
    Application.ensure_all_started(:absinthe)

    Mix.Task.run("loadpaths", argv)
    Mix.Project.compile(argv)

    opts = parse_options(argv)

    case generate_schema(opts) do
      {:ok, content} -> write_schema(content, opts.filename)
      {:error, error} -> raise error
    end
  end

  @spec generate_schema(Options.t()) :: String.t()
  def generate_schema(%Options{
        pretty: pretty,
        schema: schema,
        json_codec: json_codec
      }) do
    with {:ok, query} <- File.read(@introspection_graphql),
         {:ok, result} <- Absinthe.run(query, schema),
         {:ok, _} <- check_function_available(json_codec, :encode),
         {:ok, content} <- json_codec.encode(result, pretty: pretty) do
      {:ok, content}
    else
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  @spec parse_options([String.t()]) :: Options.t()
  def parse_options(argv) do
    parse_options = [strict: [schema: :string, json_codec: :string, pretty: :boolean]]
    {opts, args, _} = OptionParser.parse(argv, parse_options)

    %Options{
      filename: args |> List.first() || @default_filename,
      schema: find_schema(opts),
      json_codec: json_codec_as_atom(opts),
      pretty: Keyword.get(opts, :pretty, false)
    }
  end

  defp json_codec_as_atom(opts) do
    codec_name = Keyword.get(opts, :json_codec, @default_codec_name)
    String.to_atom("Elixir." <> codec_name)
  end

  defp find_schema(opts) do
    case Keyword.get(opts, :schema, Application.get_env(:absinthe, :schema)) do
      nil ->
        raise "No --schema given or :schema configured for the :absinthe application"

      value ->
        [value] |> Module.safe_concat()
    end
  end

  defp write_schema(content, filename) do
    create_directory(Path.dirname(filename))
    create_file(filename, content, force: true)
  end

  defp check_function_available(module, func) do
    available =
      Code.ensure_compiled?(module) and Keyword.has_key?(module.__info__(:functions), func)

    if available do
      {:ok, module}
    else
      {:error, "Module '#{module}' has not been loaded or does not provide '#{func}'."}
    end
  end
end
