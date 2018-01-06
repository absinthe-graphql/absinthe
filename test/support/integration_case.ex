defmodule Absinthe.IntegrationCase do

  def read_integration_file!(filename) do
    elem(Code.eval_file(filename), 0)
  end

  defp find_tests(root, default_schema) do
    for graphql_file <- Path.wildcard(Path.join(root, "**/*.graphql")) do
      dirname = Path.dirname(graphql_file)
      basename = Path.basename(graphql_file, ".graphql")
      integration_name = Path.join(String.replace_leading(dirname, root, ""), basename)
      result_file  = Path.join(dirname, basename <> ".result.exs")
      options_file = Path.join(dirname, basename <> ".options.exs")
      graphql = File.read!(graphql_file)
      schema =
        case Regex.run(~r/^#\s*schema:\s*(\S+)/i, graphql) do
          nil ->
            default_schema
          [_, schema_name] ->
            Module.concat(Absinthe.Fixtures, String.to_atom(schema_name))
        end
      options =
        case File.exists?(options_file) do
          true ->
            read_integration_file!(options_file)
          false ->
            []
        end
      integration_name = "integration '#{integration_name}' (schema: #{schema})"
      {
        integration_name,
        %{
          graphql: graphql,
          schema: schema,
          options: options,
          result_file: result_file,
        }
      }
    end
  end

  defmacro __using__(opts) do
    root = Keyword.fetch!(opts, :root)
    default_schema = Macro.expand(Keyword.fetch!(opts, :default_schema), __ENV__)
    definitions = find_tests(root, default_schema)
    quote do
      use Absinthe.Case, unquote(opts)
      @integration_tests unquote(Macro.escape(definitions))
    end
  end

end
