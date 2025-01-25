defmodule Elixir.Absinthe.Integration.Execution.Fragments.IntrospectionTest do
  use Absinthe.Case, async: true

  @query """
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

  test "scenario #1" do
    result = Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])

    assert {:ok,
            %{
              data: %{
                "__type" => %{
                  "name" => "ProfileInput",
                  "kind" => "INPUT_OBJECT",
                  "fields" => nil,
                  "inputFields" => input_fields
                }
              }
            }} = result

    correct = [
      %{"name" => "address"},
      %{"name" => "code"},
      %{"name" => "name"},
      %{"name" => "age"}
    ]

    sort = & &1["name"]
    assert Enum.sort_by(input_fields, sort) == Enum.sort_by(correct, sort)
  end
end
