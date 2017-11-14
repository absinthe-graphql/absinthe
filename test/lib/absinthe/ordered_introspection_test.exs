defmodule Absinthe.OrderedIntrospectionTest do
  use Absinthe.Case, async: false, ordered: true
  use OrdMap
  import AssertResult

  alias Absinthe.Schema

  context "introspection of an object" do
    it "returns the name of the object type currently being queried without an alias" do
      result = "{ person { __typename name } }" |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"person" => o%{"__typename" => "Person", "name" => "Bruce"}}}}, result
    end
    it "returns the name of the object type currently being queried witho an alias" do
      result = "{ person { kind: __typename name } }" |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"person" => o%{"kind" => "Person", "name" => "Bruce"}}}}, result
    end
  end

  context "introspection of an interface" do
    it "returns the name of the object type currently being queried" do
      # Without an alias
      result = "{ contact { entity { __typename name } } }" |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"contact" => o%{"entity" => o%{"__typename" => "Person", "name" => "Bruce"}}}}}, result
      # With an alias
      result = "{ contact { entity { kind: __typename name } } }" |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"contact" => o%{"entity" => o%{"kind" => "Person", "name" => "Bruce"}}}}}, result
    end
  end

  context "when querying against a union" do
    it "returns the name of the object type currently being queried" do
      # Simple type
      result = "{ firstSearchResult { __typename } }" |> run(ContactSchema)
      assert_result {:ok, %{data: o(%{"firstSearchResult" => o%{"__typename" => "Person"}})}}, result
      # Wrapped type
      result = "{ searchResults { __typename } }" |> run(ContactSchema)
      assert_result {:ok, %{data: o(%{"searchResults" => [o(%{"__typename" => "Person"}), o(%{"__typename" => "Business"})]})}}, result
    end
  end

  context "introspection of a schema" do

    it "can use __schema to get types" do
      result = "{ __schema { types { name } } }" |> run(ContactSchema)
      types = result 
        |> elem(1) 
        |> Map.get(:data) 
        |> OrdMap.get("__schema") 
        |> OrdMap.get("types")
      names = types |> Enum.map(&(OrdMap.get(&1, "name"))) |> Enum.sort
      expected = ~w(Int ID String Boolean Float Contact Person Business ProfileInput SearchResult Name NamedEntity RootMutationType RootQueryType RootSubscriptionType __Schema __Directive __DirectiveLocation __EnumValue __Field __InputValue __Type)
       |> Enum.sort
      assert expected == names
    end

    it "can use __schema to get the query type" do
      result = "{ __schema { queryType { name kind } } }" |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"__schema" => o%{"queryType" => o%{"name" => "RootQueryType", "kind" => "OBJECT"}}}}}, result
    end

    it "can use __schema to get the mutation type" do
      result = "{ __schema { mutationType { name kind } } }" |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"__schema" => o%{"mutationType" => o%{"name" => "RootMutationType", "kind" => "OBJECT"}}}}}, result
    end

    it "can use __schema to get the subscription type" do
      result = "{ __schema { subscriptionType { name kind } } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: o%{"__schema" => o%{"subscriptionType" => o%{"name" => "RootSubscriptionType", "kind" => "OBJECT"}}}}}, result
    end

    it "can use __schema to get the directives" do
      result = """
      {
        __schema {
          directives {
            args { name type { kind ofType { name kind } } }
            name
            locations
            onField
            onFragment
            onOperation
          }
        }
      }
      """ |> run(ContactSchema)
      assert {:ok, %{data: o%{"__schema" => o%{"directives" => [
        o(%{"args" => [
          o%{"name" => "if", "type" => o%{"kind" => "NON_NULL", "ofType" => o%{"name" => "Boolean", "kind" => "SCALAR"}}}
        ], "name" => "include", "locations" => [
          "INLINE_FRAGMENT", "FRAGMENT_SPREAD", "FIELD"
        ], "onField" => true, "onFragment" => true, "onOperation" => false}),
        o(%{"args" => [
          o%{"name" => "if", "type" => o%{"kind" => "NON_NULL", "ofType" => o%{"name" => "Boolean", "kind" => "SCALAR"}}}
        ], "name" => "skip", "locations" => [
          "INLINE_FRAGMENT", "FRAGMENT_SPREAD", "FIELD"
        ], "onField" => true, "onFragment" => true, "onOperation" => false})
      ]}}}} == result
    end

  end

  context "introspection of an enum type" do

    it "can use __type and value information with deprecations" do
      result = """
      {
        __type(name: "Channel") {
          name
          description
          kind
          enumValues(includeDeprecated: true) {
            name
            description
            isDeprecated
            deprecationReason
          }
        }
      }
      """
      |> run(ColorSchema)
      expected = {:ok, %{data: o(%{"__type" => o(%{"name" => "Channel", "description" => "A color channel", "kind" => "ENUM", "enumValues" => [
        o(%{"name" => "BLUE", "description" => "The color blue", "isDeprecated" => false, "deprecationReason" => nil}),
        o(%{"name" => "GREEN", "description" => "The color green", "isDeprecated" => false, "deprecationReason" => nil}),
        o(%{"name" => "PUCE", "description" => "The color puce", "isDeprecated" => true, "deprecationReason" => "it's ugly"}),
        o(%{"name" => "RED", "description" => "The color red", "isDeprecated" => false, "deprecationReason" => nil})
      ]})})}} 
      assert expected == result
    end

    it "can use __type and value information without deprecations" do
      result = """
      {
        __type(name: "Channel") {
          name
          description
          kind
          enumValues {
            name
            description
          }
        }
      }
      """
      |> run(ColorSchema)
      assert {:ok, %{data: o%{"__type" => o%{"name" => "Channel", "description" => "A color channel", "kind" => "ENUM", "enumValues" => [
        o(%{"name" => "BLUE", "description" => "The color blue"}),
        o(%{"name" => "GREEN", "description" => "The color green"}),
        o%{"name" => "RED", "description" => "The color red"}
      ]}}}} = result
    end

    it "when used as the defaultValue of an argument" do
      result = """
      {
        __schema {
          queryType {
            fields {
              name
              type {
                name
              }
              args {
                name
                defaultValue
              }
            }
          }
        }
      }
      """
      |> run(ColorSchema)
      expected = {:ok, %{data: o%{"__schema" => o%{"queryType" => o%{"fields" => [
        o%{"name" => "info", "type" => o(%{"name" => "ChannelInfo"}), "args" => [o%{"name" => "channel", "defaultValue" => "RED"}]}
      ]}}}}}
      assert expected == result
    end

    it "when used as the default value of an input object" do
      result = """
      {
        __type(name: "ChannelInput") {
          name
          inputFields {
            name
            defaultValue
          }
        }
      }
      """
      |> run(ColorSchema)
      assert {:ok, %{data: o%{"__type" => o%{"name" => "ChannelInput", "inputFields" => input_fields}}}} = result
      assert [
        o%{"name" => "channel", "defaultValue" => "RED"}
      ] = input_fields
    end
  end

  context "introspection of an input object type" do

    it "can use __type and ignore deprecated fields" do
      result = """
      {
        __type(name: "ProfileInput") {
          description
          inputFields {
            defaultValue
            description
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
          kind
          name
        }
      }
      """
      |> run(ContactSchema)
      expected = {:ok, %{data: o%{"__type" => o%{"description" => "The basic details for a person", "inputFields" => [
        o(%{"defaultValue" => "43", "description" => "The person's age", "name" => "age", "type" => o%{"kind" => "SCALAR", "name" => "Int", "ofType" => nil}}),
        o(%{"defaultValue" => nil, "description" => nil, "name" => "code", "type" => o%{"kind" => "NON_NULL", "name" => nil, "ofType" => o%{"kind" => "SCALAR", "name" => "String"}}}),
        o%{"defaultValue" => "\"Janet\"", "description" => "The person's name", "name" => "name", "type" => o%{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}
      ], "kind" => "INPUT_OBJECT", "name" => "ProfileInput"}}}}
      assert expected == result
    end

  end

  context "introspection of an interface type" do

    it "can use __type and get possible types" do
      result = """
      {
        __type(name: "NamedEntity") {
          description
          kind
          name
          possibleTypes {
            name
          }
        }
      }
      """
      |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"__type" => o%{"description" => "A named entity", "kind" => "INTERFACE", "name" => "NamedEntity", "possibleTypes" => [
        o(%{"name" => "Person"}), o%{"name" => "Business"}
      ]}}}}, result
    end

  end

  context "introspection of an object type that includes a list" do

    it "can use __type and see fields with the wrapping list types" do
      result = """
      {
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
      |> run(ContactSchema)
      assert_result {:ok,
                     %{data:
                       o%{"__type" => o%{
                          "fields" => [
        o(%{"name" => "address", "type" => o%{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}),
        o(%{"name" => "age", "type" => o%{"kind" => "SCALAR", "name" => "Int", "ofType" => nil}}),
        o(%{"name" => "name", "type" => o%{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}),
        o%{"name" => "others", "type" => o%{"kind" => "LIST", "name" => nil, "ofType" => o%{"kind" => "OBJECT", "name" => "Person"}}}
      ]}}}}, result
    end

  end


  context "introspection of an object type" do

    it "can use __type and ignore deprecated fields" do
      result = """
      {
        __type(name: "Person") {
          name
          description
          kind
          fields {
            name
          }
        }
      }
      """
      |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"__type" => o%{"name" => "Person", "description" => "A person", "kind" => "OBJECT", "fields" => [
        o(%{"name" => "age"}), o(%{"name" => "name"}), o(%{"name" => "others"})
      ]}}}}, result
    end

    it "can use __type and include deprecated fields" do
      result = """
      {
        __type(name: "Person") {
          description
          fields(includeDeprecated: true) {
            deprecationReason
            isDeprecated
            name
          }
          kind
          name
        }
      }
      """
      |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"__type" => o%{"description" => "A person", "fields" => [
        o(%{"deprecationReason" => "change of privacy policy", "isDeprecated" => true, "name" => "address"}),
        o(%{"deprecationReason" => nil, "isDeprecated" => false, "name" => "age"}),
        o(%{"deprecationReason" => nil, "isDeprecated" => false, "name" => "name"}),
        o%{"deprecationReason" => nil, "isDeprecated" => false, "name" => "others"}
      ], "kind" => "OBJECT", "name" => "Person"}}}}, result
    end

    it "can use __type to view interfaces" do
      result = """
      {
        __type(name: "Person") {
          interfaces {
            name
          }
        }
      }
      """
      |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"__type" => o%{"interfaces" => [o%{"name" => "NamedEntity"}]}}}}, result
    end

    defmodule KindSchema do
      use Absinthe.Schema

      query do
        field :foo, :foo
      end

      object :foo do
        field :name, :string
        field :kind, :string
      end

    end

    it "can use __type with a field named 'kind'" do
      result = """
      {
        __type(name: "Foo") {
          fields {
            name
            type {
              kind
              name
            }
          }
          name
        }
      }
      """
      |> run(KindSchema)
      assert {:ok, %{data: o%{
        "__type" => o%{"fields" => [
          o(%{"name" => "kind", "type" => o%{"kind" => "SCALAR", "name" => "String"}}),
          o(%{"name" => "name", "type" => o%{"kind" => "SCALAR", "name" => "String"}})
        ], 
        "name" => "Foo"}}
      }} = result
    end

    it "can use __schema with a field named 'kind'" do
      result = """
        {
          __schema {
            queryType {
              fields {
                name
                type {
                  name
                  kind
                }
              }
            }
          }
        }
      """
      |> run(KindSchema)
      assert {:ok, %{data: o%{"__schema" => o%{"queryType" => o%{"fields" => [o%{"name" => "foo", "type" => o%{"name" => "Foo", "kind" => "OBJECT"}}]}}}}} = result
    end


  end


  defmodule MySchema do
    use Absinthe.Schema

    query do
      field :greeting,
        type: :string,
        description: "A traditional greeting",
        resolve: fn
          _, _ -> {:ok, "Hah!"}
        end
    end

  end

  context "introspection of a scalar type" do
    it "can use __type" do
      result = """
      {
        __type(name: "String") {
          name
          description,
          kind
          fields {
            name
          }
        }
      }
      """
      |> run(MySchema)
      string = Schema.lookup_type(MySchema, :string)
      assert_result {:ok, %{data: o%{"__type" => o%{"name" => string.name, "description" => string.description, "kind" => "SCALAR", "fields" => nil}}}}, result
    end
  end


  context "introspection of a union type" do

    it "can use __type and get possible types" do
      result = """
      {
        __type(name: "SearchResult") {
          description
          kind
          name
          possibleTypes {
            name
          }
        }
      }
      """
      |> run(ContactSchema)
      assert_result {:ok, %{data: o%{"__type" => o%{"description" => "A search result", "kind" => "UNION", "name" => "SearchResult", "possibleTypes" => [
        o(%{"name" => "Business"}), o%{"name" => "Person"}
      ]}}}}, result
    end

  end

  context "full introspection" do

    @filename "graphql/introspection.graphql"
    @query File.read!(Path.join([:code.priv_dir(:absinthe), @filename]))

    it "runs" do
      result = @query |> run(ContactSchema)
      assert {:ok, %{data: o%{"__schema" => _}}} = result
    end

  end

end
