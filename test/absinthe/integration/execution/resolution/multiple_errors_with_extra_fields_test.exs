defmodule Elixir.Absinthe.Integration.Execution.Resolution.MultipleErrorsWithExtraFieldsTest do
  use Absinthe.Case, async: true

  @query """
  mutation { failingThing(type: MULTIPLE_WITH_CODE) { name } }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{"failingThing" => nil},
              errors: [
                %{
                  code: 1,
                  message: "Custom Error 1",
                  path: ["failingThing"],
                  locations: [%{column: 12, line: 1}]
                },
                %{
                  code: 2,
                  message: "Custom Error 2",
                  path: ["failingThing"],
                  locations: [%{column: 12, line: 1}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
