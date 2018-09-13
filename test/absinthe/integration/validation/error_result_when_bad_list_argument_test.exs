defmodule Elixir.Absinthe.Integration.Validation.ErrorResultWhenBadListArgumentTest do
  use ExUnit.Case, async: true

  @query """
  query {
    thing(id: ["foo"]) {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: "Argument \"id\" has invalid value [\"foo\"].",
                  locations: [%{column: 9, line: 2}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
