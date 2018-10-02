defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToVariableWithDefaultValueTest do
  use ExUnit.Case, async: true

  @query """
  query ($mult: Int = 6) {
    times(base: 4, multiplier: $mult)
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"times" => 24}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.TimesSchema, [])
  end

  test "scenario #2" do
    assert {:ok, %{data: %{"times" => 4}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.TimesSchema, variables: %{"mult" => nil})
  end
end
