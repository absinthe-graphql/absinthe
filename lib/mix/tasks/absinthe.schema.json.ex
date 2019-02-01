defmodule Mix.Tasks.Absinthe.Schema.Json do
  require Logger
  use Mix.Task
  import Mix.Generator

  @shortdoc "Generate a schema.json file for an Absinthe schema"

  @default_filename "./schema.json"

  @moduledoc """
  Generate a schema.json file

  ## Usage

      absinthe.schema.json [FILENAME] [OPTIONS]

    The JSON codec to be used needs to be included in your `mix.exs` dependencies. If using the default codec,
    see the Jason [installation instructions](https://hexdocs.pm/jason).

  ## Options

  * `--schema` - The name of the `Absinthe.Schema` module defining the schema to be generated.
     Default: As [configured](https://hexdocs.pm/mix/Mix.Config.html) for `:absinthe` `:schema`
  * `--json-codec` - Codec to use to generate the JSON file (see [Custom Codecs](#module-custom-codecs)).
     Default: [`Jason`](https://hexdocs.pm/jason/)
  * `--pretty` - Whether to pretty-print.
     Default: `false`


  ## Examples

  Write to default path `#{@default_filename}` using the `:schema` configured for the `:absinthe` application:

      $ mix absinthe.schema.json

  Write to default path `#{@default_filename}` using the `MySchema` schema:

      $ mix absinthe.schema.json --schema MySchema

  Write to path `/path/to/schema.json` using the `MySchema` schema, with pretty-printing:

      $ mix absinthe.schema.json --schema MySchema --pretty /path/to/schema.json

  Write to default path `#{@default_filename}` using the `MySchema` schema and a custom JSON codec, `MyCodec`:

      $ mix absinthe.schema.json --schema MySchema --json-codec MyCodec


  ## Custom Codecs

  Any module that provides `encode!/2` can be used as a custom codec:

      encode!(value, options)

  * `value` will be provided as a Map containing the generated schema.
  * `options` will be a keyword list with a `:pretty` boolean, indicating whether the user requested pretty-printing.

  The function should return a string to be written to the output file.

  """

  defmodule Options do
    @moduledoc false

    defstruct filename: nil, schema: nil, json_codec: nil, pretty: false

    @type t() :: %__MODULE__{
            filename: String.t(),
            schema: module(),
            json_codec: module(),
            pretty: boolean()
          }
  end

  @doc "Callback implementation for `Mix.Task.run/1`, which receives a list of command-line args."
  @spec run(argv :: [binary()]) :: any()
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

  @doc false
  @spec generate_schema(Options.t()) :: String.t()
  def generate_schema(%Options{
        pretty: pretty,
        schema: schema,
        json_codec: json_codec
      }) do
    with {:ok, result} <- Absinthe.Schema.introspect(schema),
         content <- json_codec.encode!(result, pretty: pretty) do
      {:ok, content}
    else
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  @doc false
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
    opts
    |> Keyword.fetch(:json_codec)
    |> case do
      {:ok, codec} -> Module.concat([codec])
      _ -> Jason
    end
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
end
