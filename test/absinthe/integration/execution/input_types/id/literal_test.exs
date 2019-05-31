defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Id.LiteralTest do
  use Absinthe.Case, async: true

  @query """
  {
    item(id: "foo") {
      id
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"item" => %{"id" => "foo", "name" => "Foo"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.IdTestSchema, [])
  end
end
