defmodule Mix.Tasks.Absinthe.Schema.Graphql do
  require Logger
  use Mix.Task
  import Mix.Generator

  @shortdoc "Generate a schema.graphql (IDL) file for an Absinthe schema"

  @default_filename "./schema.graphql"
  @default_adapter Absinthe.Adapter.LanguageConventions
  @default_adapter_name "Absinthe.Adapter.LanguageConventions"

  @moduledoc """
  Generate a schema.graphql file

  ## Usage

      absinthe.schema.graphql [OPTIONS] [FILENAME]

  ## Options

      --schema The schema. Default: As configured for `:absinthe` `:schema`
      --adapter Sets the adapter. Default: #{@default_adapter_name}

  ## Examples

  Write to default path `#{@default_filename}` using the `:schema` configured for
  the `:absinthe` application, adapting it using the default
  `#{@default_adapter_name}` adapter:

      $ mix absinthe.schema.graphql

  Write to default path `#{@default_filename}` using the `MySchema` schema, adapting
  it using the default `#{@default_adapter_name}` adapter:

      $ mix absinthe.schema.graphql --schema MySchema

  Write to path `/path/to/schema.graphql` using the `MySchema` schema, adapting
  it using the default `#{@default_adapter_name}` adapter:

      $ mix absinthe.schema.graphql --schema MySchema /path/to/schema.graphql

  Write to default path `#{@default_filename}` using the `MySchema` schema, adapting
  it using the `Absinthe.Adapter.Passthrough` adapter:

      $ mix absinthe.schema.graphql --schema MySchema --adapter Absinthe.Adapter.Passthrough

  """

  def run(argv) do
    Mix.Task.run("app.start", [])

    {opts, args, _} = OptionParser.parse(argv)

    adapter = find_adapter(opts)
    schema = find_schema(opts)
    filename = args |> List.first || @default_filename

    content = schema
    |> Absinthe.Language.IDL.to_idl_ast
    |> adapter.dump_document
    |> Absinthe.Language.IDL.to_idl_iodata(schema)

    create_directory(Path.dirname(filename))
    create_file(filename, content, force: true)
  end

  defp find_adapter(opts) do
    Keyword.get(opts, :adapter, fallback_adapter)
    |> List.wrap
    |> Module.safe_concat
  end

  defp fallback_adapter do
    Application.get_env(:absinthe, :adapter) || @default_adapter
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
