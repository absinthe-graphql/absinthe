defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToTypeNonNullListOfNonNull_TElementTest do
  use ExUnit.Case, async: true

  @query """
  # Schema: NullListsSchema
  query {
    nonNullableListOfNonNullableType(input: [null, 1]) {
      length
      content
      nonNullCount
      nullCount
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{errors: [%{message: "Argument \"input\" has invalid value [null, 1].\nIn element #1: Expected type \"Int!\", found null."}]}} == Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, [])
  end
end
