defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToTypeNonNullListOfNonNullTElementTest do
  use Absinthe.Case, async: true

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
    assert {:ok,
            %{
              errors: [
                %{
                  message:
                    "Argument \"input\" has invalid value $value.\nIn element #1: Expected type \"Int!\", found null.",
                  locations: [%{column: 36, line: 2}]
                }
              ]
            }} ==
             Absinthe.run(
               @query,
               Absinthe.Fixtures.NullListsSchema,
               variables: %{"value" => [nil, 1]}
             )
  end
end
