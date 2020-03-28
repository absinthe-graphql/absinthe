defmodule Elixir.Absinthe.Integration.Execution.Introspection.FullTest do
  use Absinthe.Case, async: true

  @query """
  query IntrospectionQuery {
    __schema {
      queryType { name }
      mutationType { name }
      subscriptionType { name }
      types {
        ...FullType
      }
      directives {
        name
        description
        locations
        args {
          ...InputValue
        }
      }
    }
  }
  fragment FullType on __Type {
    kind
    name
    description
    fields(includeDeprecated: true) {
      name
      description
      args {
        ...InputValue
      }
      type {
        ...TypeRef
      }
      isDeprecated
      deprecationReason
    }
    inputFields {
      ...InputValue
    }
    interfaces {
      ...TypeRef
    }
    enumValues(includeDeprecated: true) {
      name
      description
      isDeprecated
      deprecationReason
    }
    possibleTypes {
      ...TypeRef
    }
  }
  fragment InputValue on __InputValue {
    name
    description
    type { ...TypeRef }
    defaultValue
  }
  fragment TypeRef on __Type {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
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
      }
    }
  }
  """

  test "scenario #1" do
    result = Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
    {:ok, %{data: %{"__schema" => schema}}} = result
    assert !is_nil(schema)
  end

  defmodule MiddlewareSchema do
    use Absinthe.Schema

    query do
    end

    def middleware(_, _, _) do
      raise "this should not be called when introspecting"
    end
  end

  test "middleware callback does not apply to introspection fields" do
    assert Absinthe.run(@query, MiddlewareSchema, [])
  end
end
