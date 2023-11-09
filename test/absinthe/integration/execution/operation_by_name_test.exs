defmodule Elixir.Absinthe.Integration.Execution.OperationByNameTest do
  use Absinthe.Case, async: true

  @query """
  query ThingFoo($id: String!) {
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
                  message: """
                  Must provide a valid operation name if query contains multiple operations.

                  No operation name was given.
                  """
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end

  test "scenario #3" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: """
                  Must provide a valid operation name if query contains multiple operations.

                  The provided operation name was: "invalid"
                  """
                }
              ]
            }} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, operation_name: "invalid")
  end

  test "scenario #4" do
    assert {:ok, %{data: %{"thing" => %{"name" => "Bar"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, operation_name: "ThingBar")
  end

  @query """
  mutation First($id: String!, $thing: InputThing!) {
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

  @query """
  mutation First($id: String!, $thing: InputThing!) {
    updateThing(id: $id thing: $thing) {
      id
    }
  }
  """

  test "return error when single operation in document does not match given operation name" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: """
                  The provided operation name did not match the operation in the query.

                  The provided operation name was: "Second"
                  """
                }
              ]
            }} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, operation_name: "Second")
  end
end
