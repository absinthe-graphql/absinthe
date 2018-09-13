defmodule Elixir.Absinthe.Integration.Execution.CustomTypes.Datetime.InputObjectTest do
  use ExUnit.Case, async: true

  @query """
  mutation {
    customTypesMutation(args: { datetime: "2017-01-27T20:31:55Z" }) {
      message
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"customTypesMutation" => %{"message" => "ok"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.CustomTypesSchema, [])
  end
end
