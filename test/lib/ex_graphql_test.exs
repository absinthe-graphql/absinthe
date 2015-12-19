defmodule ExGraphQLTest do
  use ExSpec, async: true

  it "can do a simple query" do
    query = """
    query GimmeFoo {
      thing(id: "foo") {
        name
      }
    }
    """
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}, errors: []}} = run(query)
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
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}, errors: [%{message: "Field `bad': Not present in schema", locations: [%{line: 4, column: 0}]}]}} = run(query)
  end

  it "warns of unknown fields" do
    query = """
    {
      bad_resolution
    }
    """
    assert {:ok, %{data: %{},
                   errors: [%{message: "Field `bad_resolution': Did not resolve to match {:ok, _} or {:error, _}", locations: _}]}} = run(query)
  end

  it "returns the correct results for an alias" do
    query = """
    query GimmeFooByAlias {
      widget: thing(id: "foo") {
        name
      }
    }
    """
    assert {:ok, %{data: %{"widget" => %{"name" => "Foo"}}, errors: []}} = run(query)
  end

  it "checks for required arguments" do
    query = "{ thing { name } }"
    assert {:ok, %{data: %{}, errors: [%{message: "Field `thing': 1 required argument (`id') not provided"},
                                       %{message: "Argument `id' (String): Not provided"}]}} = run(query)

  end

  it "checks for extra arguments" do
    query = """
    {
      thing(id: "foo", extra: "dunno") {
        name
      }
    }
    """
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}, errors: [%{message: "Argument `extra': Not present in schema"}]}} = run(query)
  end

  @tag :focus
  it "checks for badly formed arguments" do
    query = """
    {
      number(val: "AAA")
    }
    """
    assert {:ok, %{data: %{}, errors: [%{message: "Field `number': 1 badly formed argument (`val') provided"},
                                       %{message: "Argument `val' (Int): Invalid value provided"}]}} = run(query)
  end

  @tag :focus
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
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo", "other_thing" => %{"name" => "Bar"}}}, errors: []}} = run(query)
  end

  it "can provide context" do
    query = """
      query GimmeThingByContext {
        thingByContext {
          name
        }
      }
    """
    assert {:ok, %{data: %{"thingByContext" => %{"name" => "Bar"}}, errors: []}} = run(query, context: %{thing: "bar"})
    assert {:ok, %{data: %{}, errors: [%{message: "Field `thingByContext': No :id context provided"}]}} = run(query)
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
    assert {:ok, %{data: %{"thing" => %{"name" => "Bar"}}, errors: []}} = result
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
    assert {:ok, %{data: %{"thing" => %{"name" => "Bar"}}, errors: [%{message: "Variable `other' (String): Not provided"}]}} = result
  end

  defp run(query, options \\ []) do
    ExGraphQL.run(Things.schema, query, options)
  end

end
