defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToTypeNonNullListOfTTest do
  use Absinthe.Case, async: true

  @query """
  query {
    nullableListOfNonNullableType(input: null) {
      length
      content
      nonNullCount
      nullCount
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"nullableListOfNonNullableType" => nil}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, [])
  end
end
