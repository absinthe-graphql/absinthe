defmodule Mix.Tasks.Absinthe.Schema.Json do
  require Logger
  use Mix.Task
  import Mix.Generator

  @shortdoc "Generate a schema.json file for an Absinthe schema"

  @moduledoc """
  Generate a schema.json file

  ## Usage

      absinthe.schema.json Schema.Module.Name [FILENAME]

  ## Options

    --json-codec Sets JSON Codec. Default: Poison
    --pretty Whether to pretty-print (Poison-only). Default: false

  ## Examples

      $ mix absinthe.schema.json MySchema
      $ mix absinthe.schema.json MySchema ../path/to/schema.json

  """

  @introspection_graphql Path.join([:code.priv_dir(:absinthe), "graphql", "introspection.graphql"])

  def run(argv) do
    Mix.Task.run("app.start", [])

    {opts, [schema_name|rest], _} = OptionParser.parse(argv)

    filename = rest |> List.first || "schema.json"
    json_codec = find_json(opts)
    schema = [schema_name] |> Module.safe_concat

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

end
