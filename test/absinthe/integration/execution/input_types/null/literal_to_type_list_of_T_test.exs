defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToTypeListOfTTest do
  use Absinthe.Case, async: true

  @query """
  query {
    nullableList(input: null) {
      length
      content
      nonNullCount
      nullCount
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"nullableList" => nil}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, [])
  end
end
