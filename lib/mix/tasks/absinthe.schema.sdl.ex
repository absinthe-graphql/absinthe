defmodule Mix.Tasks.Absinthe.Schema.Sdl do
  use Mix.Task
  import Mix.Generator

  @shortdoc "Generate a schema.graphql file for an Absinthe schema"

  @default_filename "./schema.graphql"

  @moduledoc """
  Generate a `schema.graphql` file.

  ## Usage

      mix absinthe.schema.sdl [OPTIONS] [FILENAME]

  ## Options

  * `--schema` - The name of the `Absinthe.Schema` module defining the schema to be generated.
     Default: As [configured](https://hexdocs.pm/mix/Mix.Config.html) for `:absinthe` `:schema`

  ## Examples

  Write to default path `#{@default_filename}` using the `:schema` configured for the `:absinthe` application:

      mix absinthe.schema.sdl

  Write to path `/path/to/schema.graphql` using the `MySchema` schema

      mix absinthe.schema.sdl --schema MySchema /path/to/schema.graphql

  """

  defmodule Options do
    @moduledoc false
    defstruct filename: nil, schema: nil

    @type t() :: %__MODULE__{
            filename: String.t(),
            schema: module()
          }
  end

  @impl Mix.Task
  def run(argv) do
    Application.ensure_all_started(:absinthe)

    Mix.Task.run("loadpaths", argv)
    Mix.Task.run("compile", argv)

    opts = parse_options(argv)

    # Start Absinthe.Schema if using persistent term provider
    if opts.schema.__absinthe_schema_provider__() == Absinthe.Schema.PersistentTerm do
      Supervisor.start_link([{Absinthe.Schema, opts.schema}], strategy: :one_for_one)
    end

    case generate_schema(opts) do
      {:ok, content} -> write_schema(content, opts.filename)
      {:error, error} -> raise error
    end
  end

  def generate_schema(%Options{schema: schema}) do
    pipeline =
      schema
      |> Absinthe.Pipeline.for_schema(prototype_schema: schema.__absinthe_prototype_schema__())
      |> Absinthe.Pipeline.upto({Absinthe.Phase.Schema.Validation.Result, pass: :final})
      |> Absinthe.Schema.apply_modifiers(schema)

    adapter =
      if function_exported?(schema, :__absinthe_adapter__, 0) do
        schema.__absinthe_adapter__()
      else
        Absinthe.Adapter.LanguageConventions
      end

    with {:ok, blueprint, _phases} <-
           Absinthe.Pipeline.run(
             schema.__absinthe_blueprint__(),
             pipeline
           ) do
      {:ok, inspect(blueprint, pretty: true, adapter: adapter)}
    else
      _ -> {:error, "Failed to render schema"}
    end
  end

  defp write_schema(content, filename) do
    create_directory(Path.dirname(filename))
    create_file(filename, content, force: true)
  end

  def parse_options(argv) do
    {opts, args, _} = OptionParser.parse(argv, strict: [schema: :string])

    %Options{
      filename: args |> List.first() || @default_filename,
      schema: find_schema(opts)
    }
  end

  defp find_schema(opts) do
    case Keyword.get(opts, :schema, Application.get_env(:absinthe, :schema)) do
      nil ->
        raise "No --schema given or :schema configured for the :absinthe application"

      value ->
        [value] |> Module.safe_concat()
    end
  end
end
