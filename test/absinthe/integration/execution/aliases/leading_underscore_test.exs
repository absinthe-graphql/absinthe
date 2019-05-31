defmodule Elixir.Absinthe.Integration.Execution.Aliases.LeadingUnderscoreTest do
  use Absinthe.Case, async: true

  @query """
  query {
    _thing123: thing(id: "foo") {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"_thing123" => %{"name" => "Foo"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
