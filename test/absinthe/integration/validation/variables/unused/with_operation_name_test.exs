defmodule Elixir.Absinthe.Integration.Validation.Variables.Unused.WithOperationNameTest do
  use ExUnit.Case, async: true

  @query """
  query AnOperationName($test: String) {
    thing(id: "foo") {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: "Variable \"test\" is never used in operation \"AnOperationName\".",
                  locations: [%{column: 23, line: 1}, %{column: 1, line: 1}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
