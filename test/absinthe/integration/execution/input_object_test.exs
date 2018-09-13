defmodule Elixir.Absinthe.Integration.Execution.InputObjectTest do
  use ExUnit.Case, async: true

  @query """
  mutation {
    updateThing(id: "foo", thing: {value: 100}) {
      name
      value
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"updateThing" => %{"name" => "Foo", "value" => 100}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
