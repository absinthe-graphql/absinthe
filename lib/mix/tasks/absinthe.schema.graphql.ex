defmodule Mix.Tasks.Absinthe.Schema.Graphql do
  require Logger
  use Mix.Task
  import Mix.Generator

  @shortdoc "Generate a schema.graphql file for an Absinthe schema"

  @moduledoc """
  Generate a schema.graphql file

  ## Usage

      absinthe.schema.graphql Schema.Module.Name [FILENAME]

  ## Examples

      $ mix absinthe.schema.graphql MySchema
      $ mix absinthe.schema.graphql MySchema ../path/to/schema.graphql

  """

  def run(argv) do
    Mix.Task.run("app.start", [])

    {opts, [schema_name|rest], _} = OptionParser.parse(argv)

    filename = rest |> List.first || "schema.graphql"
    schema = [schema_name] |> Module.safe_concat

    content = schema
    |> Absinthe.Language.IDL.to_idl_ast
    |> Absinthe.Language.IDL.to_idl_iodata

    create_directory(Path.dirname(filename))
    create_file(filename, content, force: true)
  end

end
