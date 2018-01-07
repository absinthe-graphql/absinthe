defmodule Absinthe.IntegrationTest do

  use Absinthe.IntegrationCase,
    root: "test/absinthe/integration",
    default_schema: Absinthe.Fixtures.ThingsSchema,
    async: true

  for test_definition <- @integration_tests do
    test "integration #{test_definition.name}" do
      definition = unquote(Macro.escape(test_definition))
      for setting <- definition.settings do
        case setting do
          {options, {:raise, exception}} ->
            assert_raise(
              exception,
              fn -> run(definition.graphql, definition.schema, options) end
            )
          {options, result} ->
            assert_result(
              result,
              run(definition.graphql, definition.schema, options)
            )
        end
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
