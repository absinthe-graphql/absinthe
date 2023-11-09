defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToTypeNonNullListOfNonNullTTest do
  use Absinthe.Case, async: true

  @query """
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
    assert {:ok,
            %{
              errors: [
                %{
                  message: "Argument \"input\" has invalid value null.",
                  locations: [%{column: 36, line: 2}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, [])
  end
end
