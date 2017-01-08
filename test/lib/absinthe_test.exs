defmodule AbsintheTest do
  use Absinthe.Case, async: true
  import AssertResult

  it "can return multiple errors" do
    query = "mutation { FailingThing(type: MULTIPLE) { name } }"
    assert_result {:ok, %{data: %{}, errors: [%{message: "In field \"FailingThing\": one"}, %{message: "In field \"FailingThing\": two"}]}}, run(query, Things)    
  end

  it "can return extra error fields" do
    query = "mutation { FailingThing(type: WITH_CODE) { name } }"
    assert_result {:ok, %{data: %{}, errors: [%{code: 42, message: "In field \"FailingThing\": Custom Error"}]}}, run(query, Things)
  end

  it "requires message in extended errors" do
    query = "mutation { FailingThing(type: WITHOUT_MESSAGE) { name } }"
    assert_raise Absinthe.ExecutionError, fn -> run(query, Things) end
  end

  it "can return multiple errors, with extra error fields" do
    query = "mutation { FailingThing(type: MULTIPLE_WITH_CODE) { name } }"
    assert_result {:ok, %{data: %{}, errors: [%{code: 1, message: "In field \"FailingThing\": Custom Error 1"}, %{code: 2, message: "In field \"FailingThing\": Custom Error 2"}]}}, run(query, Things)
  end

  it "requires message in extended errors, when multiple errors are given" do
    query = "mutation { FailingThing(type: MULTIPLE_WITHOUT_MESSAGE) { name } }"
    assert_raise Absinthe.ExecutionError, fn -> run(query, Things) end
  end  

  it "can do a simple query" do
    query = """
    query GimmeFoo {
      thing(id: "foo") {
        name
      }
    }
    """
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}}, run(query, Things)
  end

  it "can do a simple query with fragments" do
    query = """
    {
      ... Fields
    }

    fragment Fields on RootQueryType {
      thing(id: "foo") {
        name
      }
    }
    """
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}}, run(query, Things)
  end

  it "can do a simple query with a weird alias" do
    query = """
    query GimmeFoo {
      thing(id: "foo") {
        fOO_Bar_baz: name
      }
    }
    """
    assert_result {:ok, %{data: %{"thing" => %{"fOO_Bar_baz" => "Foo"}}}}, run(query, Things)
  end

  it "can do a simple query returning a list" do
    query = """
    query AllTheThings {
      things {
        id
        name
      }
    }
    """
    assert_result {:ok, %{data: %{"things" => [%{"name" => "Bar", "id" => "bar"}, %{"name" => "Foo", "id" => "foo"}]}}}, run(query, Things)
  end

  it "can do a simple query with an all caps alias" do
    query = """
    query GimmeFoo {
      thing(id: "foo") {
        FOO: name
      }
    }
    """
    assert_result {:ok, %{data: %{"thing" => %{"FOO" => "Foo"}}}}, run(query, Things)
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
    assert_result {:ok, %{errors: [%{message: ~s(Cannot query field "bad" on type "Thing".)}]}}, run(query, Things)
  end

  it "blows up on bad resolutions" do
    query = """
    {
      badResolution {
        name
      }
    }
    """
    assert_raise Absinthe.ExecutionError, fn -> run(query, Things) end
  end

  it "returns the correct results for an alias" do
    query = """
    query GimmeFooByAlias {
      widget: thing(id: "foo") {
        name
      }
    }
    """
    assert_result {:ok, %{data: %{"widget" => %{"name" => "Foo"}}}}, run(query, Things)
  end

  it "checks for required arguments" do
    query = "{ thing { name } }"
    assert_result {:ok, %{errors: [%{message: ~s(In argument "id": Expected type "String!", found null.)}]}}, run(query, Things)

  end

  it "checks for extra arguments" do
    query = """
    {
      thing(id: "foo", extra: "dunno") {
        name
      }
    }
    """
    assert_result {:ok, %{errors: [%{message: ~s(Unknown argument "extra" on field "thing" of type "RootQueryType".)}]}}, run(query, Things)
  end

  it "checks for badly formed arguments" do
    query = """
    {
      number(val: "AAA")
    }
    """
    assert_result {:ok, %{errors: [%{message: ~s(Argument "val" has invalid value "AAA".)}]}}, run(query, Things)
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
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo", "otherThing" => %{"name" => "Bar"}}}}}, run(query, Things)
  end

  it "can provide context" do
    query = """
      query GimmeThingByContext {
        thingByContext {
          name
        }
      }
    """
    assert_result {:ok, %{data: %{"thingByContext" => %{"name" => "Bar"}}}}, run(query, Things, context: %{thing: "bar"})
    assert_result {:ok, %{data: %{},
                          errors: [%{message: ~s(In field "thingByContext": No :id context provided)}]}}, run(query, Things)
  end

  it "can use variables" do
    query = """
    query GimmeThingByVariable($thingId: String!) {
      thing(id: $thingId) {
        name
      }
    }
    """
    result = run(query, Things, variables: %{"thingId" => "bar"})
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Bar"}}}}, result
  end

  it "can handle variable errors without an operation name" do
    query = """
    query($userId: String, $test: String) {
        user(id: $userId) {
            id
        }
    }
    """
    assert_result {:ok,
      %{errors: [
        %{message: "Cannot query field \"user\" on type \"RootQueryType\". Did you mean \"number\"?"},
        %{message: "Unknown argument \"id\" on field \"user\" of type \"RootQueryType\"."},
        %{message: "Variable \"test\" is never used."}]}
    }, run(query, Things, variables: %{"id" => "foo"})
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
    result = run(query, Things)
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
    assert_result {:ok, %{errors: [%{message: ~s(Argument "thing" has invalid value {value: "BAD"}.\nIn field "value": Expected type "Int", found "BAD".)}]}}, run(query, Things)
  end

  it "reports variables that are never used" do
    query = """
      query GimmeThingByVariable($thingId: String!, $other: String!) {
        thing(id: $thingId) {
          name
        }
      }
    """
    result = run(query, Things, variables: %{"thingId" => "bar"})
    assert_result {:ok, %{errors: [%{message: ~s(Variable "other" is never used in operation "GimmeThingByVariable".)}]}}, result
  end

  it "reports parser errors from parse" do
    query = """
      {
        thing(id: "foo") {}{ name }
      }
    """
    assert_result {:ok, %{errors: [%{message: "syntax error before: '}'"}]}}, run(query, Things)
  end

  it "reports parser errors from run" do
    query = """
      {
        thing(id: "foo") {}{ name }
      }
    """
    result = run(query, Things)
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
    |> run(Absinthe.IdTestSchema)
    assert_result {:ok, %{data: %{"item" => %{"id" => "foo", "name" => "Foo"}}}}, result
  end

  it "should wrap all lexer errors and return if not aborting to a phase" do
    query = """
    {
      item(this-won't-parse)
    }
    """

    assert {:error, "illegal: -w, on line 2"} == Absinthe.Phase.Parse.run(query, jump_phases: false)
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
    |> run(ColorSchema)
    assert_result {:ok, %{data: %{"red" => %{"name" => "RED", "value" => 100}, "green" => %{"name" => "GREEN", "value" => 200}, "blue" => %{"name" => "BLUE", "value" => 300}, "puce" => %{"name" => "PUCE", "value" => -100}}}}, result
  end

  it "should return an error when not specifying subfields" do
    query = """
      {
        things
      }
    """
    result = run(query, Things)
    assert_result {:ok, %{errors: [%{message: "Field \"things\" of type \"[Thing]\" must have a selection of subfields. Did you mean \"things { ... }\"?"}]}}, result
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
      {:ok, doc, _} = Absinthe.Pipeline.run(@simple_fragment, [Absinthe.Phase.Parse])
      assert %{definitions: [%Absinthe.Language.OperationDefinition{},
                             %Absinthe.Language.Fragment{name: "NamedPerson"}]} = doc
    end

    it "returns the correct result" do
      assert_result {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}}, run(@simple_fragment, ContactSchema)
    end

    it "returns the correct result using fragments for introspection" do
      assert {:ok, %{data: %{"__type" => %{"name" => "ProfileInput", "kind" => "INPUT_OBJECT", "fields" => nil, "inputFields" => input_fields}}}} = run(@introspection_fragment, ContactSchema)
      correct = [%{"name" => "code"}, %{"name" => "name"}, %{"name" => "age"}]
      sort = &(&1["name"])
      assert Enum.sort_by(input_fields, sort) == Enum.sort_by(correct, sort)
    end

    it "ignores fragments that can't be applied" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == run(@unapplied_fragment, ContactSchema)
    end

  end

  describe "a root_value" do

    @version "1.4.5"
    @query "{ version }"
    it "is used to resolve toplevel fields" do
      assert {:ok, %{data: %{"version" => @version}}} == run(@query, Things, root_value: %{version: @version})
    end

  end

  describe "an alias with an underscore" do

    @query """
    { _thing123:thing(id: "foo") { name } }
    """
    it "is returned intact" do
      assert {:ok, %{data: %{"_thing123" => %{"name" => "Foo"}}}} == run(@query, Things)
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
      assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}} == run(@multiple_ops_query, Things, operation_name: "ThingFoo")
    end

    it "should error when no operation name is supplied" do
      assert {:ok, %{errors: [%{message: "Must provide a valid operation name if query contains multiple operations."}]}} == run(@multiple_ops_query, Things)
    end
    it "should error when an invalid operation name is supplied" do
      op_name = "invalid"
      assert_result {:ok, %{errors: [%{message: "Must provide a valid operation name if query contains multiple operations."}]}}, run(@multiple_ops_query, Things, operation_name: op_name)
    end
  end

  it "handles cycles" do
    cycler = """
    query Foo {
      name
    }
    fragment Foo on Blag {
      name
      ...Bar
    }
    fragment Bar on Blah {
      age
      ...Foo
    }
    """
    assert_result {:ok, %{errors: [%{message: "Cannot spread fragment \"Foo\" within itself via \"Bar\", \"Foo\"."}, %{message: "Cannot spread fragment \"Bar\" within itself via \"Foo\", \"Bar\"."}]}}, run(cycler, Things)
  end

end
