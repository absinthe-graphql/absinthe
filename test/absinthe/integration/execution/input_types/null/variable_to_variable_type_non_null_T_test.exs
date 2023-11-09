defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.VariableToVariableTypeNonNullTTest do
  use Absinthe.Case, async: true

  @query """
  query ($mult: Int!) {
    times(base: 4, multiplier: $mult)
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: "Variable \"mult\": Expected non-null, found null.",
                  locations: [%{column: 8, line: 1}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.TimesSchema, variables: %{"mult" => nil})
  end

  test "scenario #2" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: "Variable \"mult\": Expected non-null, found null.",
                  locations: [%{column: 8, line: 1}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.TimesSchema, [])
  end

  test "scenario #3" do
    assert {:ok, %{data: %{"times" => 8}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.TimesSchema, variables: %{"mult" => 2})
  end
end
