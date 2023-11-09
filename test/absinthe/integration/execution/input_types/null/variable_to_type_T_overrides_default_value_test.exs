defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToTypeTOverridesDefaultValueTest do
  use Absinthe.Case, async: true

  @query """
  query ($multiplier: Int) {
    times: objTimes(input: {base: 4, multiplier: $multiplier})
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"times" => 4}}} ==
             Absinthe.run(
               @query,
               Absinthe.Fixtures.ObjectTimesSchema,
               variables: %{"multiplier" => nil}
             )
  end
end
