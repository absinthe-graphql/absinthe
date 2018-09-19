defmodule Elixir.Absinthe.Integration.Execution.Aliases.AliasTest do
  use ExUnit.Case, async: true

  # LEAVE ME

  @query """
  query {
    widget: thing(id: "foo") {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"widget" => %{"name" => "Foo"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
