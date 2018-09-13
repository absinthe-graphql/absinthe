defmodule Elixir.Absinthe.Integration.Validation.UnknownFieldTest do
  use ExUnit.Case, async: true

  @query """
  {
    thing(id: "foo") {
      name
      bad
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: "Cannot query field \"bad\" on type \"Thing\".",
                  locations: [%{column: 5, line: 4}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
