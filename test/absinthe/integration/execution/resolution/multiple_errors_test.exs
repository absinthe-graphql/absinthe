defmodule Elixir.Absinthe.Integration.Execution.Resolution.MultipleErrorsTest do
  use ExUnit.Case, async: true

  @query """
  mutation { failingThing(type: MULTIPLE) { name } }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{"failingThing" => nil},
              errors: [
                %{message: "one", path: ["failingThing"], locations: [%{column: 12, line: 1}]},
                %{message: "two", path: ["failingThing"], locations: [%{column: 12, line: 1}]}
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
