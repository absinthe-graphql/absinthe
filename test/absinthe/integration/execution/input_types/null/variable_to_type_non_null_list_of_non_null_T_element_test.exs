defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToTypeNonNullListOfNonNull_TElementTest do
  use ExUnit.Case, async: true

  @query """
  # Schema: NullListsSchema
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
    assert {:ok, %{errors: [%{message: "Argument \"input\" has invalid value $value.\nIn element #1: Expected type \"Int!\", found null."}]}} == Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, [variables: %{"value" => [nil, 1]}])
  end
end
