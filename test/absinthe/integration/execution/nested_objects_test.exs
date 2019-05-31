defmodule Elixir.Absinthe.Integration.Execution.NestedObjectsTest do
  use Absinthe.Case, async: true

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
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
