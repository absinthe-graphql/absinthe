defmodule Elixir.Absinthe.Integration.Execution.CustomTypes.BasicTest do
  use ExUnit.Case, async: true

  @query """
  query {
    customTypesQuery { datetime }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"customTypesQuery" => %{"datetime" => "2017-01-27T20:31:55Z"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.CustomTypesSchema, [])
  end
end
