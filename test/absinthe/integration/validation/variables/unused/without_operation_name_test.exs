defmodule Elixir.Absinthe.Integration.Validation.Variables.Unused.WithoutOperationNameTest do
  use ExUnit.Case, async: true

  @query """
  query ($test: String) {
    thing(id: "foo") {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{message: "Variable \"test\" is never used.", locations: [%{column: 8, line: 1}]}
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
