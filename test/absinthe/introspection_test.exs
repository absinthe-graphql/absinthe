defmodule Absinthe.IntrospectionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Schema

  describe "introspection of directives" do
    # Note: @defer and @stream directives are opt-in and not included in core schemas.
    # They need to be explicitly imported via: import_directives Absinthe.Type.BuiltIns.IncrementalDirectives
    test "builtin" do
      result =
        """
        query IntrospectionQuery {
          __schema {
            directives {
              name
              description
              locations
              isRepeatable
              onOperation
              onFragment
              onField
            }
          }
        }
        """
        |> run(Absinthe.Fixtures.ColorSchema)

      assert {:ok,
              %{
                data: %{
                  "__schema" => %{
                    "directives" => [
                      %{
                        "description" =>
                          "Marks an element of a GraphQL schema as no longer supported.",
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
                        "description" => nil,
                        "isRepeatable" => false,
                        "locations" => ["FIELD_DEFINITION"],
                        "name" => "external",
                        "onField" => false,
                        "onFragment" => false,
                        "onOperation" => false
                      },
                      %{
                        "description" =>
                          "Directs the executor to include this field or fragment only when the `if` argument is true.",
                        "isRepeatable" => false,
                        "locations" => ["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
                        "name" => "include",
                        "onField" => true,
                        "onFragment" => true,
                        "onOperation" => false
                      },
                      %{
                        "description" =>
                          "The @oneOf built-in directive is used within the type system definition language to indicate an Input Object is a OneOf Input Object.\n\nA OneOf Input Object is a special variant of Input Object where exactly one field must be set and non-null, all others being omitted.\nThis is useful for representing situations where an input may be one of many different options.",
                        "isRepeatable" => false,
                        "locations" => ["INPUT_OBJECT"],
                        "name" => "oneOf",
                        "onField" => false,
                        "onFragment" => false,
                        "onOperation" => false
                      },
                      %{
                        "description" =>
                          "Directs the executor to skip this field or fragment when the `if` argument is true.",
                        "isRepeatable" => false,
                        "locations" => ["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
                        "name" => "skip",
                        "onField" => true,
                        "onFragment" => true,
                        "onOperation" => false
                      },
                      %{
                        "description" =>
                          "Exposes a URL that specifies the behavior of this scalar.",
                        "isRepeatable" => false,
                        "locations" => ["SCALAR"],
                        "name" => "specifiedBy",
                        "onField" => false,
                        "onFragment" => false,
                        "onOperation" => false
                      }
                    ]
                  }
                }
              }} = result
    end
  end

  describe "introspection of complex directives" do
    defmodule ComplexDirectiveSchema do
      use Absinthe.Schema
      use Absinthe.Fixture

      defmodule Utils do
        def parse(value), do: value
        def serialize(value), do: value
      end

      defmodule ComplexDirectivePrototype do
        use Absinthe.Schema.Prototype

        input_object :complex do
          field :str, :string
        end

        scalar :normal_string, description: "string" do
          parse &Utils.parse/1
          serialize &Utils.serialize/1
        end

        scalar :_underscore_normal_string, name: "_UnderscoreNormalString" do
          parse &Utils.parse/1
          serialize &Utils.serialize/1
        end

        enum :color_channel do
          description "The selected color channel"
          value :red, as: :r, description: "Color Red"
          value :green, as: :g, description: "Color Green"
          value :blue, as: :b, description: "Color Blue"
        end

        directive :complex_directive do
          arg :complex, :complex
          arg :normal_string, :normal_string
          arg :color_channel, :color_channel
          arg :_underscore_normal_string, :_underscore_normal_string

          on [:field]
        end
      end

      @prototype_schema ComplexDirectivePrototype

      query do
        field :foo,
          type: :string,
          args: [],
          resolve: fn _, _ -> {:ok, "foo"} end
      end
    end

    test "renders type for complex directives" do
      result =
        """
        query IntrospectionQuery {
          __schema {
            types {
              name
            }
            directives {
              name
              args {
                name
                description
                type {
                  kind
                  name
                }
                defaultValue
              }
            }
          }
        }
        """
        |> run(ComplexDirectiveSchema)

      assert {:ok,
              %{
                data: %{
                  "__schema" => %{
                    "directives" => [
                      %{"name" => "complexDirective", "args" => complex_directive_args}
                      | _
                    ],
                    "types" => types
                  }
                }
              }} = result

      assert Enum.member?(
               complex_directive_args,
               %{
                 "type" => %{
                   "kind" => "INPUT_OBJECT",
                   "name" => "Complex"
                 },
                 "defaultValue" => nil,
                 "description" => nil,
                 "name" => "complex"
               }
             )

      assert Enum.member?(types, %{"name" => "Complex"})

      assert Enum.member?(
               complex_directive_args,
               %{
                 "type" => %{
                   "kind" => "SCALAR",
                   "name" => "NormalString"
                 },
                 "defaultValue" => nil,
                 "description" => nil,
                 "name" => "normalString"
               }
             )

      assert Enum.member?(types, %{"name" => "NormalString"})

      assert Enum.member?(
               complex_directive_args,
               %{
                 "type" => %{
                   "kind" => "ENUM",
                   "name" => "ColorChannel"
                 },
                 "defaultValue" => nil,
                 "description" => nil,
                 "name" => "colorChannel"
               }
             )

      assert Enum.member?(types, %{"name" => "ColorChannel"})

      assert Enum.member?(
               complex_directive_args,
               %{
                 "type" => %{
                   "kind" => "SCALAR",
                   "name" => "_UnderscoreNormalString"
                 },
                 "defaultValue" => nil,
                 "description" => nil,
                 "name" => "_underscoreNormalString"
               }
             )

      assert Enum.member?(types, %{"name" => "_UnderscoreNormalString"})
    end
  end

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
             ] == values
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

      assert %{"name" => "info", "args" => [%{"name" => "channel", "defaultValue" => "RED"}]} in fields
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

    test "includes deprecated fields based on an arg" do
      result =
        """
        {
          __type(name: "ProfileInput") {
            kind
            name
            description
            inputFields(includeDeprecated: true) {
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
               "description" => "The basic details for a person",
               "inputFields" => [
                 %{
                   "defaultValue" => nil,
                   "description" => nil,
                   "name" => "address",
                   "type" => %{
                     "kind" => "SCALAR",
                     "name" => "String",
                     "ofType" => nil
                   },
                   "deprecationReason" => "change of privacy policy",
                   "isDeprecated" => true
                 },
                 %{
                   "defaultValue" => "43",
                   "description" => "The person's age",
                   "name" => "age",
                   "type" => %{"kind" => "SCALAR", "name" => "Int", "ofType" => nil},
                   "deprecationReason" => nil,
                   "isDeprecated" => false
                 },
                 %{
                   "defaultValue" => nil,
                   "description" => nil,
                   "name" => "code",
                   "type" => %{
                     "kind" => "NON_NULL",
                     "name" => nil,
                     "ofType" => %{"kind" => "SCALAR", "name" => "String"}
                   },
                   "deprecationReason" => nil,
                   "isDeprecated" => false
                 },
                 %{
                   "defaultValue" => "\"Janet\"",
                   "description" => "The person's name",
                   "name" => "name",
                   "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil},
                   "deprecationReason" => nil,
                   "isDeprecated" => false
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

    test "can remove deprecated fields based on an arg" do
      result =
        """
        {
          __type(name: "ProfileInput") {
            kind
            name
            description
            inputFields(includeDeprecated: false) {
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
               "description" => "The basic details for a person",
               "inputFields" => [
                 %{
                   "defaultValue" => "43",
                   "description" => "The person's age",
                   "name" => "age",
                   "type" => %{"kind" => "SCALAR", "name" => "Int", "ofType" => nil},
                   "deprecationReason" => nil,
                   "isDeprecated" => false
                 },
                 %{
                   "defaultValue" => nil,
                   "description" => nil,
                   "name" => "code",
                   "type" => %{
                     "kind" => "NON_NULL",
                     "name" => nil,
                     "ofType" => %{"kind" => "SCALAR", "name" => "String"}
                   },
                   "deprecationReason" => nil,
                   "isDeprecated" => false
                 },
                 %{
                   "defaultValue" => "\"Janet\"",
                   "description" => "The person's name",
                   "name" => "name",
                   "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil},
                   "deprecationReason" => nil,
                   "isDeprecated" => false
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

    defmodule ComplexDefaultSchema do
      use Absinthe.Schema

      query do
        field :complex_default, :string do
          arg :input, :complex_input,
            default_value: %{
              fancy_value: "qwerty",
              fancy_nested: %{fancy_bool: false},
              fancy_enum: :foo,
              fancy_list: [:foo, :bar]
            }
        end
      end

      enum :an_enum do
        value :foo
        value :bar
      end

      input_object :complex_input do
        field :fancy_value, :string
        field :fancy_enum, non_null(:an_enum)
        field :fancy_list, list_of(:an_enum)
        field :fancy_nested, :nested_complex_input
      end

      input_object :nested_complex_input do
        field :fancy_bool, :boolean
      end
    end

    test "can introspect complex default_value" do
      result =
        """
        {
          __schema {
            queryType {
              fields {
                args {
                  defaultValue
                }
              }
            }
          }
        }
        """
        |> run(ComplexDefaultSchema)

      assert_result(
        {:ok,
         %{
           data: %{
             "__schema" => %{
               "queryType" => %{
                 "fields" => [
                   %{
                     "args" => [
                       %{
                         "defaultValue" =>
                           "{fancyEnum: FOO, fancyList: [FOO, BAR], fancyNested: {fancyBool: false}, fancyValue: \"qwerty\"}"
                       }
                     ]
                   }
                 ]
               }
             }
           }
         }},
        result
      )
    end

    defmodule ImportFieldsIntoInputSchema do
      use Absinthe.Schema

      query do
        field :test, :test_object do
          arg :test, :test_input
        end
      end

      object :test_object do
        import_fields(:import_object)
      end

      input_object :test_input do
        import_fields(:import_object)
      end

      object :import_object do
        field :id, :id
      end
    end

    test "import_fields won't import __typename" do
      {:ok, %{data: data}} =
        """
        {
          __schema {
            types {
              name
              inputFields {
                name
              }
            }
          }
        }
        """
        |> Absinthe.run(ImportFieldsIntoInputSchema)

      type =
        get_in(data, ["__schema", "types"])
        |> Enum.find(&(&1["name"] == "TestInput"))

      assert get_in(type, ["inputFields"]) == [%{"name" => "id"}]
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

  test "Doesn't fail for unknown introspection fields" do
    result =
      """
      {
        __foobar {
          baz
        }
      }
      """
      |> run(Absinthe.Fixtures.ContactSchema)

    assert_result(
      {:ok,
       %{
         errors: [
           %{
             locations: [%{column: 3, line: 2}],
             message: "Cannot query field \"__foobar\" on type \"RootQueryType\"."
           }
         ]
       }},
      result
    )
  end

  test "properly render partial default value input objects" do
    {:ok, result} =
      """
      {
        __schema {
          queryType {
            fields {
              name
              args {
                name
                defaultValue
              }
            }
          }
        }
      }
      """
      |> run(Absinthe.Fixtures.ArgumentsSchema)

    fields = get_in(result, [:data, "__schema", "queryType", "fields"])

    assert %{
             "args" => [
               %{"defaultValue" => "{exclude: [2, 3], include: [1]}", "name" => "filterAll"},
               %{"defaultValue" => "{}", "name" => "filterEmpty"},
               %{"defaultValue" => "{exclude: [1, 2, 3]}", "name" => "filterExclude"},
               %{"defaultValue" => "{include: [1, 2, 3]}", "name" => "filterInclude"}
             ],
             "name" => "filterNumbers"
           } in fields
  end
end
