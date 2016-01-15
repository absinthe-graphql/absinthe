defmodule GraphIQLTest do
  use ExSpec, async: true

  describe "for graphiql" do

    @introspection_query """
      query IntrospectionQuery {
        __schema {
          queryType { name }
          mutationType { name }
          types {
            ...FullType
          }
          directives {
            name
            description
            args {
              ...InputValue
            }
            onOperation
            onFragment
            onField
          }
        }
      }

      fragment FullType on __Type {
        kind
        name
        description
        fields {
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
        enumValues {
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
            }
          }
        }
      }
    """

    it "supports introspection" do
      result = Absinthe.run(@introspection_query, ContactSchema)
      assert !match?({:ok, %{errors: _}}, result)
      assert {:ok, %{data: %{"__schema" => %{"types" => types}}}} = result
      assert Enum.find(types, &(&1["name"] == "SearchResult"))
      assert Enum.find(types, &(&1["name"] == "Person"))
      assert Enum.find(types, &(&1["name"] == "ProfileInput"))
    end

  end

end
