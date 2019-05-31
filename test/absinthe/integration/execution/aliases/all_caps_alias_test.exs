defmodule Elixir.Absinthe.Integration.Execution.Aliases.AllCapsAliasTest do
  use Absinthe.Case, async: true

  @query """
  query {
    thing(id: "foo") {
      FOO: name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"thing" => %{"FOO" => "Foo"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
