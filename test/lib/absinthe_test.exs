defmodule AbsintheTest do
  use ExSpec, async: true
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
    assert_result {:ok, %{errors: [%{message: "Field `thing': 1 required argument (`id') not provided", locations: [%{column: 0, line: 1}]},
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
    assert_result {:ok, %{errors: [%{message: "Field `number': 1 badly formed argument (`val') provided"},
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
    assert_result {:ok, %{errors: [%{message: "Field `thingByContext': No :id context provided"}]}}, run(query)
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
    assert_result {:ok, %{errors: [%{message: "Field `updateThing': 1 badly formed argument (`thing.value') provided"},
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
    result = run(query, variables: %{thingId: "bar"})
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Bar"}}, errors: [%{locations: [%{column: 0, line: 1}], message: "Variable `other' (String): Not provided"}]}}, result
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

  describe "validate/2" do

    it "alwars returns :ok for now" do
      {:ok, doc} = Absinthe.parse("{ does_not_exist { name } }")
      assert :ok == Absinthe.validate(doc, Things)
    end

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
        red: info(channel: "red") {
          name
          value
        }
        green: info(channel: "green") {
          name
          value
        }
        blue: info(channel: "blue") {
          name
          value
        }
        puce: info(channel: "puce") {
          name
          value
        }
      }
    """
    |> Absinthe.run(ColorSchema)
    assert_result {:ok, %{data: %{"red" => %{"name" => "RED", "value" => 100}, "green" => %{"name" => "GREEN", "value" => 200}, "blue" => %{"name" => "BLUE", "value" => 300}, "puce" => %{"name" => "PUCE", "value" => -100}},
                          errors: [%{message: "Argument `channel' (Channel): Enum value \"puce\" deprecated; it's ugly"}]}}, result
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

    it 'can be parsed' do
      {:ok, doc} = Absinthe.parse(@simple_fragment)
      assert %{definitions: [%Absinthe.Language.OperationDefinition{},
                             %Absinthe.Language.Fragment{name: "NamedPerson"}]} = doc
    end

  end

  defp run(query, options \\ []) do
    query
    |> Absinthe.run(Things, options)
  end

end
