defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToTypeTTest do
  use Absinthe.Case, async: true

  @query """
  query ($value: Int) {
    times: objTimes(input: {base: 4, multiplier: $value})
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"times" => 4}}} ==
             Absinthe.run(
               @query,
               Absinthe.Fixtures.ObjectTimesSchema,
               variables: %{"value" => nil}
             )
  end

  test "scenario #2" do
    assert {:ok, %{data: %{"times" => 32}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ObjectTimesSchema, variables: %{"value" => 8})
  end
end
