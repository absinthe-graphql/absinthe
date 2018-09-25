defmodule Elixir.Absinthe.Integration.Execution.NestedObjectsTest do
  use ExUnit.Case, async: true

  @query """
  query {
    thing(id: "foo") {
      name
      otherThing {
        name
      }
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo", "otherThing" => %{"name" => "Bar"}}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
