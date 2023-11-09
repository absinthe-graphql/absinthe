defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToTypeListOfTElementTest do
  use Absinthe.Case, async: true

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
    assert {:ok,
            %{
              data: %{
                "nullableList" => %{
                  "content" => [nil, 1],
                  "length" => 2,
                  "nonNullCount" => 1,
                  "nullCount" => 1
                }
              }
            }} ==
             Absinthe.run(
               @query,
               Absinthe.Fixtures.NullListsSchema,
               variables: %{"value" => [nil, 1]}
             )
  end
end
