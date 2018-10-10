defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToTypeNonNullListOf_TTest do
  use ExUnit.Case, async: true

  @query """
  query ($value: [Int!]) {
    nullableListOfNonNullableType(input: $value) {
      length
      content
      nonNullCount
      nullCount
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"nullableListOfNonNullableType" => nil}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, variables: %{"value" => nil})
  end
end
