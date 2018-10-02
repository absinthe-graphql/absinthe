defmodule Elixir.Absinthe.Integration.Execution.Introspection.DirectivesTest do
  use ExUnit.Case, async: true

  @query """
  query {
    __schema {
      directives {
        name
        args { name type { kind ofType { name kind } } }
        locations
        onField
        onFragment
        onOperation
      }
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "__schema" => %{
                  "directives" => [
                    %{
                      "args" => [
                        %{
                          "name" => "if",
                          "type" => %{
                            "kind" => "NON_NULL",
                            "ofType" => %{"kind" => "SCALAR", "name" => "Boolean"}
                          }
                        }
                      ],
                      "locations" => ["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
                      "name" => "include",
                      "onField" => true,
                      "onFragment" => true,
                      "onOperation" => false
                    },
                    %{
                      "args" => [
                        %{
                          "name" => "if",
                          "type" => %{
                            "kind" => "NON_NULL",
                            "ofType" => %{"kind" => "SCALAR", "name" => "Boolean"}
                          }
                        }
                      ],
                      "locations" => ["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
                      "name" => "skip",
                      "onField" => true,
                      "onFragment" => true,
                      "onOperation" => false
                    }
                  ]
                }
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
