defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToElementOfTypeNonNullListOf_TTest do
  use ExUnit.Case, async: true

  @query """
  query {
    nonNullableList(input: [null, 1]) {
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
                "nonNullableList" => %{
                  "content" => [nil, 1],
                  "length" => 2,
                  "nonNullCount" => 1,
                  "nullCount" => 1
                }
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.NullListsSchema, [])
  end
end
