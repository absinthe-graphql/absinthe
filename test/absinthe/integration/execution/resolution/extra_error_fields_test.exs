defmodule Elixir.Absinthe.Integration.Execution.Resolution.ExtraErrorFieldsTest do
  use ExUnit.Case, async: true

  @query """
  mutation { failingThing(type: WITH_CODE) { name } }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{"failingThing" => nil},
              errors: [
                %{
                  code: 42,
                  message: "Custom Error",
                  path: ["failingThing"],
                  locations: [%{column: 12, line: 1}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
