defmodule AbsintheTest do
  use Absinthe.Case, async: true
  import AssertResult

  it "can do a simple query" do
    query = """
    query GimmeFoo {
      thing(id: "foo") {
        name
      }
    }
    """
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}}, run(query)
  end

  it "can identify a bad field" do
    query = """
    {
      thing(id: "foo") {
        name
        bad
      }
    }
    """
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}}, errors: [%{message: "Field `bad': Not present in schema", locations: [%{line: 4, column: 0}]}]}}, run(query)
  end

  it "warns of unknown fields" do
    query = """
    {
      badResolution
    }
    """
    assert {:ok, %{errors: [%{message: "Field `badResolution': Did not resolve to match {:ok, _} or {:error, _}", locations: _}]}} = run(query)
  end

  it "returns the correct results for an alias" do
    query = """
    query GimmeFooByAlias {
      widget: thing(id: "foo") {
        name
      }
    }
    """
    assert_result {:ok, %{data: %{"widget" => %{"name" => "Foo"}}}}, run(query)
  end

  it "checks for required arguments" do
    query = "{ thing { name } }"
    assert_result {:ok, %{data: %{},
                          errors: [%{message: "Field `thing': 1 required argument (`id') not provided", locations: [%{column: 0, line: 1}]},
                            %{message: "Argument `id' (String): Not provided", locations: [%{column: 0, line: 1}]}]}}, run(query)

  end

  it "checks for extra arguments" do
    query = """
    {
      thing(id: "foo", extra: "dunno") {
        name
      }
    }
    """
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}}, errors: [%{message: "Argument `extra': Not present in schema"}]}}, run(query)
  end

  it "checks for badly formed arguments" do
    query = """
    {
      number(val: "AAA")
    }
    """
    assert_result {:ok, %{data: %{},
                         errors: [%{message: "Field `number': 1 badly formed argument (`val') provided"},
                                  %{message: "Argument `val' (Int): Invalid value provided"}]}}, run(query)
  end

  it "returns nested objects" do
    query = """
    query GimmeFooWithOtherThing {
      thing(id: "foo") {
        name
        otherThing {
          name
        }
      }
    }
    """
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo", "otherThing" => %{"name" => "Bar"}}}}}, run(query)
  end

  it "can provide context" do
    query = """
      query GimmeThingByContext {
        thingByContext {
          name
        }
      }
    """
    assert_result {:ok, %{data: %{"thingByContext" => %{"name" => "Bar"}}}}, run(query, context: %{thing: "bar"})
    assert_result {:ok, %{data: %{},
                          errors: [%{message: "Field `thingByContext': No :id context provided"}]}}, run(query)
  end

  it "can use variables" do
    query = """
    query GimmeThingByVariable($thingId: String!) {
      thing(id: $thingId) {
        name
      }
    }
    """
    result = run(query, variables: %{"thingId" => "bar"})
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Bar"}}}}, result
  end

  it "can use input objects" do
    query = """
    mutation UpdateThingValue {
      thing: update_thing(id: "foo", thing: {value: 100}) {
        name
        value
      }
    }
    """
    result = run(query)
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo", "value" => 100}}}}, result
  end

  it "checks for badly formed nested arguments" do
    query = """
    mutation UpdateThingValueBadly {
      thing: updateThing(id: "foo", thing: {value: "BAD"}) {
        name
        value
      }
    }
    """
    assert_result {:ok, %{data: %{},
                         errors: [%{message: "Field `updateThing': 1 badly formed argument (`thing.value') provided"},
                                  %{message: "Argument `thing.value' (Int): Invalid value provided"}]}}, run(query)
  end

  it "reports missing, required variable values" do
    query = """
      query GimmeThingByVariable($thingId: String!, $other: String!) {
        thing(id: $thingId) {
          name
        }
      }
    """
    result = run(query, variables: %{"thingId" => "bar"})
    assert_result {:ok, %{data: %{}, errors: [%{message: "Variable `other' (String): Not provided"}]}}, result
  end

  it "reports parser errors from parse" do
    query = """
      {
        thing(id: "foo") {}{ name }
      }
    """
    assert {:error, %{message: "syntax error before: '}'", locations: _}} = Absinthe.parse(query)
  end

  it "reports parser errors from run" do
    query = """
      {
        thing(id: "foo") {}{ name }
      }
    """
    result = run(query)
    assert_result {:ok, %{errors: [%{message: "syntax error before: '}'"}]}}, result
  end

  it "Should be retrievable using the ID type as a string" do
    result = """
    {
      item(id: "foo") {
        id
        name
      }
    }
    """
    |> Absinthe.run(Absinthe.IdTestSchema)
    assert_result {:ok, %{data: %{"item" => %{"id" => "foo", "name" => "Foo"}}}}, result
  end

  it "Should be retrievable using the ID type as a bare value" do
    result = """
    {
      item(id: foo) {
        id
        name
      }
    }
    """
    |> Absinthe.run(Absinthe.IdTestSchema)
    assert_result {:ok, %{data: %{"item" => %{"id" => "foo", "name" => "Foo"}}}}, result
  end

  it "should wrap all lexer errors" do
    query = """
    {
      item(this-won't-parse)
    }
    """

    assert {:error, %{locations: _}} = Absinthe.parse(query)
  end

  it "should resolve using enums" do
    result = """
      {
        red: info(channel: RED) {
          name
          value
        }
        green: info(channel: GREEN) {
          name
          value
        }
        blue: info(channel: BLUE) {
          name
          value
        }
        puce: info(channel: PUCE) {
          name
          value
        }
      }
    """
    |> Absinthe.run(ColorSchema)
    assert_result {:ok, %{data: %{"red" => %{"name" => "RED", "value" => 100}, "green" => %{"name" => "GREEN", "value" => 200}, "blue" => %{"name" => "BLUE", "value" => 300}, "puce" => %{"name" => "PUCE", "value" => -100}}, errors: [%{message: "Argument `channel.p' (Channel): Deprecated; it's ugly"}]}}, result
  end

  describe "fragments" do

    @simple_fragment """
      query Q {
        person {
          ...NamedPerson
        }
      }
      fragment NamedPerson on Person {
        name
      }
    """

    @unapplied_fragment """
      query Q {
        person {
          name
          ...NamedBusiness
        }
      }
      fragment NamedBusiness on Business {
        employee_count
      }
    """

    @introspection_fragment """
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

    it "can be parsed" do
      {:ok, doc} = Absinthe.parse(@simple_fragment)
      assert %{definitions: [%Absinthe.Language.OperationDefinition{},
                             %Absinthe.Language.Fragment{name: "NamedPerson"}]} = doc
    end

    it "returns the correct result" do
      assert_result {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}}, Absinthe.run(@simple_fragment, ContactSchema)
    end

    it "returns the correct result using fragments for introspection" do
      assert {:ok, %{data: %{"__type" => %{"name" => "ProfileInput", "kind" => "INPUT_OBJECT", "fields" => nil, "inputFields" => input_fields}}}} = Absinthe.run(@introspection_fragment, ContactSchema)
      correct = [%{"name" => "code"}, %{"name" => "name"}, %{"name" => "age"}]
      sort = &(&1["name"])
      assert Enum.sort_by(input_fields, sort) == Enum.sort_by(correct, sort)
    end

    it "ignores fragments that can't be applied" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == Absinthe.run(@unapplied_fragment, ContactSchema)
    end

  end

  describe "a root_value" do

    @version "1.4.5"
    @query "{ version }"
    it "is used to resolve toplevel fields" do
      assert {:ok, %{data: %{"version" => @version}}} == run(@query, root_value: %{version: @version})
    end

  end

  describe "an alias with an underscore" do

    @query """
    { _thing123:thing(id: "foo") { name } }
    """
    it "is returned intact" do
      assert {:ok, %{data: %{"_thing123" => %{"name" => "Foo"}}}} == run(@query)
    end

  end

  describe "multiple operation documents" do
    @multiple_ops_query """
    query ThingFoo {
      thing(id: "foo") {
        name
      }
    }
    query ThingBar {
      thing(id: "bar") {
        name
      }
    }
    """

    it "can select an operation by name" do
      assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}} == Absinthe.run(@multiple_ops_query, Things, operation_name: "ThingFoo")
    end

    it "should error when no operation name is supplied" do
      assert {:error, "Multiple operations available, but no operation_name provided"} == Absinthe.run(@multiple_ops_query, Things)
    end

    it "should error when an invalid operation name is supplied" do
      op_name = "invalid"
      assert {:error, "No operation with name: #{op_name}"} == Absinthe.run(@multiple_ops_query, Things, operation_name: op_name)
    end
  end

  defp run(query, options \\ []) do
    query
    |> Absinthe.run(Things, options)
  end

end
