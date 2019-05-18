defmodule Elixir.Absinthe.Integration.Validation.InvalidArgumentTest do
  use Absinthe.Case, async: true

  @query """
  query { number(val: "AAA") }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: "Argument \"val\" has invalid value \"AAA\".",
                  locations: [%{column: 16, line: 1}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
