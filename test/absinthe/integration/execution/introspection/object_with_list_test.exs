defmodule Elixir.Absinthe.Integration.Execution.Introspection.ObjectWithListTest do
  use Absinthe.Case, async: true

  @query """
  query {
    __type(name: "Person") {
      fields(include_deprecated: true) {
        name
        type {
          kind
          name
          ofType {
            kind
            name
          }
        }
      }
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "__type" => %{
                  "fields" => [
                    %{
                      "name" => "address",
                      "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}
                    },
                    %{
                      "name" => "age",
                      "type" => %{"kind" => "SCALAR", "name" => "Int", "ofType" => nil}
                    },
                    %{
                      "name" => "name",
                      "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}
                    },
                    %{
                      "name" => "others",
                      "type" => %{
                        "kind" => "LIST",
                        "name" => nil,
                        "ofType" => %{"kind" => "OBJECT", "name" => "Person"}
                      }
                    }
                  ]
                }
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
