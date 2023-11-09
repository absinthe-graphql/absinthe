defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToTypeNonNullTTest do
  use Absinthe.Case, async: true

  @query """
  query {
    times: objTimes(input: {base: null})
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message:
                    "Argument \"input\" has invalid value {base: null}.\nIn field \"base\": Expected type \"Int!\", found null.",
                  locations: [%{column: 19, line: 2}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ObjectTimesSchema, [])
  end
end
