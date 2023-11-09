defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToTypeNonNullListOfTElementTest do
  use Absinthe.Case, async: true

  @query """
  {
    nullableListOfNonNullableType(input: [null, 1]) {
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
                  message:
                    "Argument \"input\" has invalid value [null, 1].\nIn element #1: Expected type \"Int!\", found null.",
                  locations: [%{column: 33, line: 2}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, [])
  end
end
