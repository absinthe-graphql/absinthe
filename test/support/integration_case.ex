defmodule Absinthe.IntegrationCase do

  def read_file!(filename) do
    elem(Code.eval_file(filename), 0)
  end

  defp definitions(root, default_schema) do
    for graphql_file <- Path.wildcard(Path.join(root, "**/*.graphql")) do
      dirname = Path.dirname(graphql_file)
      basename = Path.basename(graphql_file, ".graphql")
      integration_name =
        String.replace_leading(dirname, root, "")
        |> Path.join(basename)
      graphql = File.read!(graphql_file)
      raw_settings =
        Path.join(dirname, basename <> ".exs")
        |> read_file!
      __MODULE__.Definition.create(
        integration_name,
        graphql,
        default_schema,
        raw_settings
      )
    end
  end

  defmacro __using__(opts) do
    root = Keyword.fetch!(opts, :root)
    default_schema = Macro.expand(Keyword.fetch!(opts, :default_schema), __ENV__)
    definitions = definitions(root, default_schema)
    quote do
      use Absinthe.Case, unquote(opts)
      @integration_tests unquote(Macro.escape(definitions))
    end
  end

end
