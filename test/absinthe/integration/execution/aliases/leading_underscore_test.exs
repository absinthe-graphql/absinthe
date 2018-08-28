defmodule Elixir.Absinthe.Integration.Execution.Aliases.LeadingUnderscoreTest do
  use ExUnit.Case, async: true

  @query """
  query {
    _thing123: thing(id: "foo") {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"_thing123" => %{"name" => "Foo"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
