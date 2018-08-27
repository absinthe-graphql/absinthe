defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToTypeNonNullListOf_TTest do
  use ExUnit.Case, async: true

  @query """
  # Schema: NullListsSchema
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
    assert {:ok, %{data: %{"nullableListOfNonNullableType" => nil}}} == Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, [])
  end
end
