defmodule Elixir.Absinthe.Integration.Execution.OperationByNameTest do
  use Absinthe.Case, async: true

  @query """
  query ThingFoo($id: ID!) {
    thing(id: $id) {
      name
    }
  }
  query ThingBar {
    thing(id: "bar") {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema,
               operation_name: "ThingFoo",
               variables: %{"id" => "foo"}
             )
  end

  test "scenario #2" do
    assert {:ok,
            %{
              errors: [
                %{
                  message:
                    "Must provide a valid operation name if query contains multiple operations."
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end

  test "scenario #3" do
    assert {:ok,
            %{
              errors: [
                %{
                  message:
                    "Must provide a valid operation name if query contains multiple operations."
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, operation_name: "invalid")
  end

  test "scenario #4" do
    assert {:ok, %{data: %{"thing" => %{"name" => "Bar"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, operation_name: "ThingBar")
  end

  @query """
  mutation First($id: ID!, $thing: InputThing!) {
    first: updateThing(id: $id thing: $thing) {
      id
    }
  }
  mutation Second {
    second: failingThing(type: WITH_CODE) {
      id
    }
  }
  query Third {
    third: thing(id: "bar") {
      name
    }
  }
  """

  test "scenario #5" do
    assert {:ok,
            %{
              data: %{"second" => nil},
              errors: [
                %{
                  code: 42,
                  locations: [%{column: 3, line: 7}],
                  message: "Custom Error",
                  path: ["second"]
                }
              ]
            }} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, operation_name: "Second")
  end
end
