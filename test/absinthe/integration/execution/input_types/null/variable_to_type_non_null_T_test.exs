defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToTypeNonNullTTest do
  use Absinthe.Case, async: true

  @query """
  query ($value: Int!) { times: objTimes(input: {base: $value}) }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message:
                    "Argument \"input\" has invalid value {base: $value}.\nIn field \"base\": Expected type \"Int!\", found $value.",
                  locations: [%{column: 40, line: 1}]
                },
                %{
                  message: "Variable \"value\": Expected non-null, found null.",
                  locations: [%{column: 8, line: 1}]
                }
              ]
            }} ==
             Absinthe.run(
               @query,
               Absinthe.Fixtures.ObjectTimesSchema,
               variables: %{"value" => nil}
             )
  end

  test "scenario #2" do
    assert {:ok, %{data: %{"times" => 16}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ObjectTimesSchema, variables: %{"value" => 8})
  end
end
