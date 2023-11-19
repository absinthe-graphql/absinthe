defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToTypeTOverridesDefaultValueTest do
  use Absinthe.Case, async: true

  @query """
  query {
    times: objTimes(input: {base: 4, multiplier: null})
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"times" => 4}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ObjectTimesSchema, [])
  end
end
