defmodule Elixir.Absinthe.Integration.Execution.Introspection.DirectivesTest do
  use Absinthe.Case, async: true

  @query """
  query {
    __schema {
      directives {
        name
        args { name type { kind ofType { name kind } } }
        locations
        isRepeatable
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
                        %{"name" => "reason", "type" => %{"kind" => "SCALAR", "ofType" => nil}}
                      ],
                      "isRepeatable" => false,
                      "locations" => [
                        "ARGUMENT_DEFINITION",
                        "ENUM_VALUE",
                        "FIELD_DEFINITION",
                        "INPUT_FIELD_DEFINITION"
                      ],
                      "name" => "deprecated",
                      "onField" => false,
                      "onFragment" => false,
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
                      "name" => "include",
                      "onField" => true,
                      "onFragment" => true,
                      "onOperation" => false,
                      "isRepeatable" => false
                    },
                    %{
                      "args" => [],
                      "isRepeatable" => false,
                      "locations" => ["INPUT_OBJECT"],
                      "name" => "oneOf",
                      "onField" => false,
                      "onFragment" => false,
                      "onOperation" => false
                    },
                    %{
                      "args" => [
                        %{
                          "name" => "levels",
                          "type" => %{
                            "kind" => "NON_NULL",
                            "ofType" => %{"kind" => "LIST", "name" => nil}
                          }
                        }
                      ],
                      "isRepeatable" => false,
                      "locations" => ["FIELD_DEFINITION"],
                      "name" => "semanticNonNull",
                      "onField" => false,
                      "onFragment" => false,
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
                      "onOperation" => false,
                      "isRepeatable" => false
                    },
                    %{
                      "isRepeatable" => false,
                      "locations" => ["SCALAR"],
                      "name" => "specifiedBy",
                      "onField" => false,
                      "onFragment" => false,
                      "onOperation" => false,
                      "args" => [
                        %{
                          "name" => "url",
                          "type" => %{
                            "kind" => "NON_NULL",
                            "ofType" => %{"kind" => "SCALAR", "name" => "String"}
                          }
                        }
                      ]
                    }
                  ]
                }
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
