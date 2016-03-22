defmodule Mix.Tasks.Absinthe.Schema.Graphql do
  require Logger
  use Mix.Task
  import Mix.Generator

  @shortdoc "Generate a schema.graphql file for an Absinthe schema"

  @moduledoc """
  Generate a schema.graphql file

  ## Usage

      absinthe.schema.graphql Schema.Module.Name [FILENAME]

  ## Options

    --adapter Sets the adapter. Default: Absinthe.Adapter.LanguageConventions

  ## Examples

      $ mix absinthe.schema.graphql MySchema
      $ mix absinthe.schema.graphql MySchema ../path/to/schema.graphql
      $ mix absinthe.schema.graphql MySchema --adapter Absinthe.Adapter.Passthrough

  """

  def run(argv) do
    Mix.Task.run("app.start", [])

    {opts, [schema_name|rest], _} = OptionParser.parse(argv)

    filename = rest |> List.first || "schema.graphql"
    adapter = find_adapter(opts)
    schema = [schema_name] |> Module.safe_concat

    content = schema
    |> Absinthe.Language.IDL.to_idl_ast
    |> adapter.dump_document
    |> Absinthe.Language.IDL.to_idl_iodata

    IO.puts "OK"

    create_directory(Path.dirname(filename))
    create_file(filename, content, force: true)
  end

  defp find_adapter(opts) do
    Keyword.get(opts, :adapter, Absinthe.Adapter.LanguageConventions)
  end

end
