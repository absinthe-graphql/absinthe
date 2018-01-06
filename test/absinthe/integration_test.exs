defmodule Absinthe.IntegrationTest do
  use Absinthe.Case, async: true

  alias Absinthe.Fixtures

  schemas = %{
    "basics" => Fixtures.ThingsSchema
  }

  @root "test/absinthe/integration"

  load = &(elem(Code.eval_file(&1), 0))

  for {schema_name, schema} <- schemas do
    schema_dir = Path.join(@root, schema_name)
    for graphql_file <- Path.wildcard(Path.join(schema_dir, "*.graphql")) do
      basename = Path.basename(graphql_file, ".graphql")
      result_file  = Path.join(schema_dir, basename <> ".result.exs")
      options_file = Path.join(schema_dir, basename <> ".options.exs")
      graphql = File.read!(graphql_file)
      options =
        case File.exists?(options_file) do
          true ->
            load.(options_file)
          false ->
            []
        end
      case File.exists?(result_file) do
        true ->
          result = load.(result_file)
          test to_string(basename) do
            assert_result(
              unquote(Macro.escape(result)),
              run(unquote(graphql), unquote(schema), unquote(Macro.escape(options)))
            )
          end
        false ->
          test to_string(basename) do
            assert_raise(
              Absinthe.ExecutionError,
              fn -> run(unquote(graphql), unquote(schema), unquote(Macro.escape(options))) end
            )
          end
      end
    end
  end

end
