defmodule Elixir.Absinthe.Integration.Execution.Aliases.DifferentSelectionSetsTest do
  use Absinthe.Case, async: true

  @query """
  query {
    thing1: thing(id: "foo") {
      id
    }
    thing2: thing(id: "bar") {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"thing1" => %{"id" => "foo"}, "thing2" => %{"name" => "Bar"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
