defmodule Elixir.Absinthe.Integration.Execution.ContextTest do
  use ExUnit.Case, async: true

  @query """
  query {
    thingByContext {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"thingByContext" => %{"name" => "Bar"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, context: %{thing: "bar"})
  end
end
