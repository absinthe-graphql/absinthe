defmodule Elixir.Absinthe.Integration.Execution.SimpleQueryTest do
  use Absinthe.Case, async: true

  @query """
  query { thing(id: "foo") { name } }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
