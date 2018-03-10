defmodule Absinthe.IntrospectionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Schema

  describe "introspection of an enum type" do
    test "can use __type and value information with deprecations" do
      result =
        """
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
        |> run(Absinthe.Fixtures.ColorSchema)

      assert {:ok,
              %{
                data: %{
                  "__type" => %{
                    "name" => "Channel",
                    "description" => "A color channel",
                    "kind" => "ENUM",
                    "enumValues" => values
                  }
                }
              }} = result

      assert [
               %{
                 "name" => "BLUE",
                 "description" => "The color blue",
                 "isDeprecated" => false,
                 "deprecationReason" => nil
               },
               %{
                 "name" => "GREEN",
                 "description" => "The color green",
                 "isDeprecated" => false,
                 "deprecationReason" => nil
               },
               %{
                 "name" => "PUCE",
                 "description" => "The color puce",
                 "isDeprecated" => true,
                 "deprecationReason" => "it's ugly"
               },
               %{
                 "name" => "RED",
                 "description" => "The color red",
                 "isDeprecated" => false,
                 "deprecationReason" => nil
               }
             ] == values |> Enum.sort_by(& &1["name"])
    end

    test "can use __type and value information without deprecations" do
      result =
        """
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
        |> run(Absinthe.Fixtures.ColorSchema)

      assert {:ok,
              %{
                data: %{
                  "__type" => %{
                    "name" => "Channel",
                    "description" => "A color channel",
                    "kind" => "ENUM",
                    "enumValues" => values
                  }
                }
              }} = result

      assert [
               %{"name" => "BLUE", "description" => "The color blue"},
               %{"name" => "GREEN", "description" => "The color green"},
               %{"name" => "RED", "description" => "The color red"}
             ] == values |> Enum.sort_by(& &1["name"])
    end

    test "when used as the defaultValue of an argument" do
      result =
        """
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
        |> run(Absinthe.Fixtures.ColorSchema)

      assert {:ok, %{data: %{"__schema" => %{"queryType" => %{"fields" => fields}}}}} = result

      assert [
               %{"name" => "info", "args" => [%{"name" => "channel", "defaultValue" => "RED"}]}
             ] = fields
    end
  end

  describe "introspection of an input object type" do
    test "can use __type and ignore deprecated fields" do
      result =
        """
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
        |> run(Absinthe.Fixtures.ContactSchema)

      assert_result(
        {:ok,
         %{
           data: %{
             "__type" => %{
               "description" => "The basic details for a person",
               "inputFields" => [
                 %{
                   "defaultValue" => "43",
                   "description" => "The person's age",
                   "name" => "age",
                   "type" => %{"kind" => "SCALAR", "name" => "Int", "ofType" => nil}
                 },
                 %{
                   "defaultValue" => nil,
                   "description" => nil,
                   "name" => "code",
                   "type" => %{
                     "kind" => "NON_NULL",
                     "name" => nil,
                     "ofType" => %{"kind" => "SCALAR", "name" => "String"}
                   }
                 },
                 %{
                   "defaultValue" => "\"Janet\"",
                   "description" => "The person's name",
                   "name" => "name",
                   "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}
                 }
               ],
               "kind" => "INPUT_OBJECT",
               "name" => "ProfileInput"
             }
           }
         }},
        result
      )

      assert !match?({:ok, %{data: %{"__type" => %{"fields" => _}}}}, result)
    end
  end

  describe "introspection of an object type" do
    test "can use __type and ignore deprecated fields" do
      result =
        """
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
        |> run(Absinthe.Fixtures.ContactSchema)

      assert_result(
        {:ok,
         %{
           data: %{
             "__type" => %{
               "name" => "Person",
               "description" => "A person",
               "kind" => "OBJECT",
               "fields" => [%{"name" => "age"}, %{"name" => "name"}, %{"name" => "others"}]
             }
           }
         }},
        result
      )
    end

    test "can use __type and include deprecated fields" do
      result =
        """
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
        |> run(Absinthe.Fixtures.ContactSchema)

      assert_result(
        {:ok,
         %{
           data: %{
             "__type" => %{
               "description" => "A person",
               "fields" => [
                 %{
                   "deprecationReason" => "change of privacy policy",
                   "isDeprecated" => true,
                   "name" => "address"
                 },
                 %{"deprecationReason" => nil, "isDeprecated" => false, "name" => "age"},
                 %{"deprecationReason" => nil, "isDeprecated" => false, "name" => "name"},
                 %{"deprecationReason" => nil, "isDeprecated" => false, "name" => "others"}
               ],
               "kind" => "OBJECT",
               "name" => "Person"
             }
           }
         }},
        result
      )
    end

    test "can use __type to view interfaces" do
      result =
        """
        {
          __type(name: "Person") {
            interfaces {
              name
            }
          }
        }
        """
        |> run(Absinthe.Fixtures.ContactSchema)

      assert_result(
        {:ok, %{data: %{"__type" => %{"interfaces" => [%{"name" => "NamedEntity"}]}}}},
        result
      )
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

    test "can use __type with a field named 'kind'" do
      result =
        """
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
        |> run(KindSchema)

      assert {:ok,
              %{
                data: %{
                  "__type" => %{
                    "fields" => [
                      %{"name" => "kind", "type" => %{"kind" => "SCALAR", "name" => "String"}},
                      %{"name" => "name", "type" => %{"kind" => "SCALAR", "name" => "String"}}
                    ],
                    "name" => "Foo"
                  }
                }
              }} = result
    end

    test "can use __schema with a field named 'kind'" do
      result =
        """
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

      assert {:ok,
              %{
                data: %{
                  "__schema" => %{
                    "queryType" => %{
                      "fields" => [
                        %{"name" => "foo", "type" => %{"name" => "Foo", "kind" => "OBJECT"}}
                      ]
                    }
                  }
                }
              }} = result
    end
  end

  defmodule MySchema do
    use Absinthe.Schema

    query do
      field :greeting,
        type: :string,
        description: "A traditional greeting",
        resolve: fn _, _ -> {:ok, "Hah!"} end
    end
  end

  describe "introspection of a scalar type" do
    test "can use __type" do
      result =
        """
        {
          __type(name: "String") {
            kind
            name
            description,
            fields {
              name
            }
          }
        }
        """
        |> run(MySchema)

      string = Schema.lookup_type(MySchema, :string)

      assert_result(
        {:ok,
         %{
           data: %{
             "__type" => %{
               "name" => string.name,
               "description" => string.description,
               "kind" => "SCALAR",
               "fields" => nil
             }
           }
         }},
        result
      )
    end
  end

  describe "introspection of a union type" do
    test "can use __type and get possible types" do
      result =
        """
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
        |> run(Absinthe.Fixtures.ContactSchema)

      assert_result(
        {:ok,
         %{
           data: %{
             "__type" => %{
               "description" => "A search result",
               "kind" => "UNION",
               "name" => "SearchResult",
               "possibleTypes" => [%{"name" => "Business"}, %{"name" => "Person"}]
             }
           }
         }},
        result
      )
    end
  end
end
