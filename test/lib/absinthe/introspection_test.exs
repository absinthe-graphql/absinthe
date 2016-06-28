defmodule Absinthe.IntrospectionTest do
  use Absinthe.Case, async: true
  import AssertResult

  alias Absinthe.Schema

  describe "introspection of an object" do
    it "returns the name of the object type currently being queried" do
      # Without an alias
      result = "{ person { __typename name } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"person" => %{"name" => "Bruce", "__typename" => "Person"}}}}, result
      # With an alias
      result = "{ person { kind: __typename name } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"person" => %{"name" => "Bruce", "kind" => "Person"}}}}, result
    end
  end

  describe "introspection of an interface" do
    it "returns the name of the object type currently being queried" do
      # Without an alias
      result = "{ contact { entity { __typename name } } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"contact" => %{"entity" => %{"name" => "Bruce", "__typename" => "Person"}}}}}, result
      # With an alias
      result = "{ contact { entity { kind: __typename name } } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"contact" => %{"entity" => %{"name" => "Bruce", "kind" => "Person"}}}}}, result
    end
  end

  describe "when querying against a union" do
    @tag :pending
    it "returns the name of the object type currently being queried" do
    end
  end

  describe "introspection of a schema" do

    it "can use __schema to get types" do
      {:ok, %{data: %{"__schema" => %{"types" => types}}}} = Absinthe.run(
        "{ __schema { types { name } } }",
        ContactSchema
      )
      names = types |> Enum.map(&(&1["name"])) |> Enum.sort
      expected = ~w(Int ID String Boolean Float Contact Person Business ProfileInput SearchResult NamedEntity RootMutationType RootQueryType __Schema __Directive __DirectiveLocation __EnumValue __Field __InputValue __Type) |> Enum.sort
      assert expected == names
    end

    it "can use __schema to get the query type" do
      result = "{ __schema { queryType { name kind } } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__schema" => %{"queryType" => %{"name" => "RootQueryType", "kind" => "OBJECT"}}}}}, result
    end

    it "can use __schema to get the mutation type" do
      result = "{ __schema { mutationType { name kind } } }" |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__schema" => %{"mutationType" => %{"name" => "RootMutationType", "kind" => "OBJECT"}}}}}, result
    end

    it "can use __schema to get the directives" do
      result = "{ __schema { directives { name args { name type { kind ofType { name kind } } } locations onField onFragment onOperation } } }" |> Absinthe.run(ContactSchema)
      assert {:ok,
              %{errors: _,
                data: %{"__schema" => %{
                         "directives" => [
                         %{"args" => [%{"name" => "if", "type" => %{"kind" => "NON_NULL", "ofType" => %{"kind" => "SCALAR", "name" => "Boolean"}}}], "name" => "include", "locations" => ["INLINE_FRAGMENT", "FRAGMENT_SPREAD", "FIELD"], "onField" => true, "onFragment" => true, "onOperation" => false},
                         %{"args" => [%{"name" => "if", "type" => %{"kind" => "NON_NULL", "ofType" => %{"kind" => "SCALAR", "name" => "Boolean"}}}], "name" => "skip", "locations" => ["INLINE_FRAGMENT", "FRAGMENT_SPREAD", "FIELD"], "onField" => true, "onFragment" => true, "onOperation" => false}]}}}} = result
    end

  end

  describe "introspection of an enum type" do

    it "can use __type and value information with deprecations" do
      result = """
      {
        __type(name: "Channel") {
          kind
          name
          description
          enumValues(includeDeprecated: true) {
            name
            description
            isDeprecated
            deprecationReason
          }
        }
      }
      """
      |> Absinthe.run(ColorSchema)
      assert {:ok, %{data: %{"__type" => %{"name" => "Channel", "description" => "A color channel", "kind" => "ENUM", "enumValues" => values}}}} = result
      assert [
        %{"name" => "BLUE", "description" => "The color blue", "isDeprecated" => false, "deprecationReason" => nil},
        %{"name" => "GREEN", "description" => "The color green", "isDeprecated" => false, "deprecationReason" => nil},
        %{"name" => "PUCE", "description" => "The color puce", "isDeprecated" => true, "deprecationReason" => "it's ugly"},
        %{"name" => "RED", "description" => "The color red", "isDeprecated" => false, "deprecationReason" => nil}
      ] == values |> Enum.sort_by(&(&1["name"]))
    end

    it "can use __type and value information without deprecations" do
      result = """
      {
        __type(name: "Channel") {
          kind
          name
          description
          enumValues {
            name
            description
          }
        }
      }
      """
      |> Absinthe.run(ColorSchema)
      assert {:ok, %{data: %{"__type" => %{"name" => "Channel", "description" => "A color channel", "kind" => "ENUM", "enumValues" => values}}}} = result
      assert [
        %{"name" => "BLUE", "description" => "The color blue"},
        %{"name" => "GREEN", "description" => "The color green"},
        %{"name" => "RED", "description" => "The color red"}
      ] == values |> Enum.sort_by(&(&1["name"]))
    end

  end

  describe "introspection of an input object type" do

    it "can use __type and ignore deprecated fields" do
      result = """
      {
        __type(name: "ProfileInput") {
          kind
          name
          description
          inputFields {
            name
            description
            type {
              kind
              name
              ofType {
                kind
                name
              }
            }
            defaultValue
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"description" => "The basic details for a person",
             "inputFields" => [%{"defaultValue" => "43", "description" => "The person's age", "name" => "age", "type" => %{"kind" => "SCALAR", "name" => "Int", "ofType" => nil}},
              %{"defaultValue" => nil, "description" => nil, "name" => "code", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String"}}},
              %{"defaultValue" => "\"Janet\"", "description" => "The person's name", "name" => "name", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}], "kind" => "INPUT_OBJECT", "name" => "ProfileInput"}}}},
              result
      assert !match?({:ok, %{data: %{"__type" => %{"fields" => _}}}}, result)
    end

  end

  describe "introspection of an interface type" do

    it "can use __type and get possible types" do
      result = """
      {
        __type(name: "NamedEntity") {
          kind
          name
          description
          possibleTypes {
            name
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"description" => "A named entity", "kind" => "INTERFACE", "name" => "NamedEntity", "possibleTypes" => [%{"name" => "Person"}, %{"name" => "Business"}]}}}}, result
    end

  end

  describe "introspection of an object type that includes a list" do

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
      |> Absinthe.run(ContactSchema)
      assert_result {:ok,
                     %{data:
                       %{"__type" => %{
                          "fields" => [
        %{"name" => "address", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
        %{"name" => "age", "type" => %{"kind" => "SCALAR", "name" => "Int", "ofType" => nil}},
        %{"name" => "name", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
        %{"name" => "others", "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "Person"}}}
      ]}}}}, result
    end

  end


  describe "introspection of an object type" do

    it "can use __type and ignore deprecated fields" do
      result = """
      {
        __type(name: "Person") {
          kind
          name
          description
          fields {
            name
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"name" => "Person", "description" => "A person", "kind" => "OBJECT", "fields" => [%{"name" => "age"}, %{"name" => "name"}, %{"name" => "others"}]}}}}, result
    end

    it "can use __type and include deprecated fields" do
      result = """
      {
        __type(name: "Person") {
          kind
          name
          description
          fields(includeDeprecated: true) {
            name
            isDeprecated
            deprecationReason
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"description" => "A person",
                 "fields" => [%{"deprecationReason" => "change of privacy policy", "isDeprecated" => true, "name" => "address"}, %{"deprecationReason" => nil, "isDeprecated" => false, "name" => "age"},
                  %{"deprecationReason" => nil, "isDeprecated" => false, "name" => "name"}, %{"deprecationReason" => nil, "isDeprecated" => false, "name" => "others"}], "kind" => "OBJECT", "name" => "Person"}}}}, result
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
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"interfaces" => [%{"name" => "NamedEntity"}]}}}}, result
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
          name
          fields {
            name
            type {
              name
              kind
            }
          }
        }
      }
      """
      |> Absinthe.run(KindSchema)
      assert {:ok, %{data: %{"__type" => %{"fields" => [%{"name" => "kind", "type" => %{"kind" => "SCALAR", "name" => "String"}}, %{"name" => "name", "type" => %{"kind" => "SCALAR", "name" => "String"}}], "name" => "Foo"}}}} = result
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
      |> Absinthe.run(KindSchema)
      assert {:ok, %{data: %{"__schema" => %{"queryType" => %{"fields" => [%{"name" => "foo", "type" => %{"name" => "Foo", "kind" => "OBJECT"}}]}}}}} = result
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

  describe "introspection of a scalar type" do
    it "can use __type" do
      result = """
      {
        __type(name: "String") {
          kind
          name
          description,
          fields
        }
      }
      """
      |> Absinthe.run(MySchema)
      string = Schema.lookup_type(MySchema, :string)
      assert_result {:ok, %{data: %{"__type" => %{"name" => string.name, "description" => string.description, "kind" => "SCALAR", "fields" => nil}}}}, result
    end
  end


  describe "introspection of a union type" do

    it "can use __type and get possible types" do
      result = """
      {
        __type(name: "SearchResult") {
          kind
          name
          description
          possibleTypes {
            name
          }
        }
      }
      """
      |> Absinthe.run(ContactSchema)
      assert_result {:ok, %{data: %{"__type" => %{"description" => "A search result", "kind" => "UNION", "name" => "SearchResult", "possibleTypes" => [%{"name" => "Business"}, %{"name" => "Person"}]}}}}, result
    end

  end


end
