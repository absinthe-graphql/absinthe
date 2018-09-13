defmodule Elixir.Absinthe.Integration.Execution.OperationByNameTest do
  use ExUnit.Case, async: true

  @query """
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

  test "scenario #1" do
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, operation_name: "ThingFoo")
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
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
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
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, operation_name: "invalid")
  end
end
