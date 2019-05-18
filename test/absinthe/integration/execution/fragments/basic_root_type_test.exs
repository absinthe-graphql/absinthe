defmodule Elixir.Absinthe.Integration.Execution.Fragments.BasicRootTypeTest do
  use Absinthe.Case, async: true

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
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
