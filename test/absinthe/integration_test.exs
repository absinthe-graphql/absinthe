defmodule Absinthe.IntegrationTest do
  use Absinthe.Case, async: true

    @default_schema Absinthe.Fixtures.ThingsSchema
  @root "test/absinthe/integration"

  load = &(elem(Code.eval_file(&1), 0))

  for graphql_file <- Path.wildcard(Path.join(@root, "**/*.graphql")) do
    dirname = Path.dirname(graphql_file)
    basename = Path.basename(graphql_file, ".graphql")
    integration_name = Path.join(String.replace_leading(dirname, @root, ""), basename)
    result_file  = Path.join(dirname, basename <> ".result.exs")
    options_file = Path.join(dirname, basename <> ".options.exs")
    graphql = File.read!(graphql_file)
    schema =
      case Regex.run(~r/^#\s*schema:\s*(\S+)/i, graphql) do
        nil ->
          @default_schema
        [_, schema_name] ->
          Module.concat(Absinthe.Fixtures, String.to_atom(schema_name))
      end
    options =
      case File.exists?(options_file) do
        true ->
          load.(options_file)
        false ->
          []
      end
    integration_name = "integration '#{integration_name}' (schema: #{schema})"
    case File.exists?(result_file) do
      true ->
        result = load.(result_file)
        test integration_name do
          assert_result(
            unquote(Macro.escape(result)),
            run(unquote(graphql), unquote(schema), unquote(Macro.escape(options)))
          )
        end
      false ->
        test integration_name do
          assert_raise(
            Absinthe.ExecutionError,
            fn -> run(unquote(graphql), unquote(schema), unquote(Macro.escape(options))) end
          )
        end
    end
  end

  # Integration tests requiring special assertions
  # TODO: Support special assertions in exs alongside graphql

  @graphql """
  query Q {
    __type(name: "ProfileInput") {
      name
      kind
      fields {
        name
      }
      ...Inputs
    }
  }

  fragment Inputs on __Type {
    inputFields { name }
  }
  """
  test "fragment with introspection" do
    assert {:ok, %{data: %{"__type" => %{"name" => "ProfileInput", "kind" => "INPUT_OBJECT", "fields" => nil, "inputFields" => input_fields}}}} = run(@graphql, Absinthe.Fixtures.ContactSchema)
    correct = [%{"name" => "code"}, %{"name" => "name"}, %{"name" => "age"}]
    sort = &(&1["name"])
    assert Enum.sort_by(input_fields, sort) == Enum.sort_by(correct, sort)
  end

end
