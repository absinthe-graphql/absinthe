defmodule Elixir.Absinthe.Integration.Execution.SimpleQueryReturningListTest do
  use Absinthe.Case, async: true

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
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
