defmodule Elixir.Absinthe.Integration.Execution.SimpleQueryReturningListTest do
  use ExUnit.Case, async: true

  @query """
  query {
    things {
      id
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "things" => [%{"id" => "bar", "name" => "Bar"}, %{"id" => "foo", "name" => "Foo"}]
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
