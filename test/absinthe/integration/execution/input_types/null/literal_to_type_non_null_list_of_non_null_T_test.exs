defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToTypeNonNullListOfNonNull_TTest do
  use ExUnit.Case, async: true

  @query """
  # Schema: NullListsSchema
  query {
    nonNullableListOfNonNullableType(input: null) {
      length
      content
      nonNullCount
      nullCount
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{errors: [%{message: "Argument \"input\" has invalid value null."}]}} == Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, [])
  end
end
