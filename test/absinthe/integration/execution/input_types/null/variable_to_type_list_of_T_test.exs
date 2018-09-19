defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToTypeListOf_TTest do
  use ExUnit.Case, async: true

  @query """
  query ($value: [Int]) {
    nullableList(input: $value) {
      length
      content
      nonNullCount
      nullCount
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"nullableList" => nil}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, variables: %{"value" => nil})
  end
end
