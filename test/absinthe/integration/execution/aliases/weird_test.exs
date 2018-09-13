defmodule Elixir.Absinthe.Integration.Execution.Aliases.WeirdTest do
  use ExUnit.Case, async: true

  @query """
  query {
    thing(id: "foo") {
      fOO_Bar_baz: name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"thing" => %{"fOO_Bar_baz" => "Foo"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
