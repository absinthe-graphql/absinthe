defmodule Elixir.Absinthe.Integration.Execution.Fragments.BasicRootTypeTest do
  use ExUnit.Case, async: true

  @query """
  query {
    ... Fields
  }

  fragment Fields on RootQueryType {
    thing(id: "foo") {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
