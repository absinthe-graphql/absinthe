defmodule Mix.Tasks.Absinthe.Schema.Json do
  require Logger
  use Mix.Task
  import Mix.Generator

  @shortdoc "Generate a schema.json file for an Absinthe schema"

  @default_filename "./schema.json"
  @default_codec_name "Poison"

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

  def run(argv) do
    Mix.Task.run("app.start", [])

    {opts, args, _} = OptionParser.parse(argv)

    schema = find_schema(opts)
    json_codec = find_json(opts)
    filename = args |> List.first || @default_filename

    {:ok, query} = File.read(@introspection_graphql)

    case Absinthe.run(query, schema) do
      {:ok, result} ->
        create_directory(Path.dirname(filename))
        content = json_codec.module.encode!(result, json_codec.opts)
        create_file(filename, content, force: true)
      {:error, error} ->
        raise error
    end
  end

  defp find_json(opts) do
    case Keyword.get(opts, :json_codec, Poison) do
      module when is_atom(module) ->
        %{module: module, opts: codec_opts(module, opts)}
      other ->
        other
    end
  end

  defp codec_opts(Poison, opts) do
    [pretty: Keyword.get(opts, :pretty, false)]
  end
  defp codec_opts(_, _) do
    []
  end

  defp find_schema(opts) do
    case Keyword.get(opts, :schema, Application.get_env(:absinthe, :schema)) do
      nil ->
        raise "No --schema given or :schema configured for the :absinthe application"
      value ->
        [value] |> Module.safe_concat
    end
  end

end
