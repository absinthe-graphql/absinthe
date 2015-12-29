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
      bad_resolution
    }
    """
    assert {:ok, %{errors: [%{message: "Field `bad_resolution': Did not resolve to match {:ok, _} or {:error, _}", locations: _}]}} = run(query)
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
        other_thing {
          name
        }
      }
    }
    """
    assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo", "other_thing" => %{"name" => "Bar"}}}}}, run(query)
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
      thing: update_thing(id: "foo", thing: {value: "BAD"}) {
        name
        value
      }
    }
    """
    assert_result {:ok, %{errors: [%{message: "Field `update_thing': 1 badly formed argument (`thing.value') provided"},
                            %{message: "Argument `thing.value' (Int): Invalid value provided"}]}}, run(query)
  end

  @tag :focus
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

  defp run(query, options \\ []) do
    query
    |> Absinthe.run(Things, options)
  end

end
