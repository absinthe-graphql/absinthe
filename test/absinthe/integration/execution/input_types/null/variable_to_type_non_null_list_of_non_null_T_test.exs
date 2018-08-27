defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToTypeNonNullListOfNonNull_TTest do
  use ExUnit.Case, async: true

  @query """
  query ($value: [Int!]!) {
    nonNullableListOfNonNullableType(input: $value) {
      length
      content
      nonNullCount
      nullCount
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{errors: [%{message: "Argument \"input\" has invalid value $value."},
                            %{message: "Variable \"value\": Expected non-null, found null.", locations: [%{column: 8, line: 1}]}]}} == Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, [variables: %{"value" => nil}])
  end
end
