defmodule Absinthe.IntegrationTest do

  use Absinthe.IntegrationCase,
    root: "test/absinthe/integration",
    default_schema: Absinthe.Fixtures.ThingsSchema,
    async: true

  for {name, definition} <- @integration_tests do
    case File.exists?(definition.result_file) do
      true ->
        result = Absinthe.IntegrationCase.read_integration_file!(definition.result_file)
        test name do
          assert_result(
            unquote(Macro.escape(result)),
            run(unquote(definition.graphql), unquote(definition.schema), unquote(Macro.escape(definition.options)))
          )
        end
      false ->
        test name do
          assert_raise(
            Absinthe.ExecutionError,
            fn -> run(unquote(definition.graphql), unquote(definition.schema), unquote(Macro.escape(definition.options))) end
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
