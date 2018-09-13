defmodule Elixir.Absinthe.Integration.Validation.InvalidNestedTypeTest do
  use ExUnit.Case, async: true

  @query """
  mutation UpdateThingValueBadly {
    thing: updateThing(id: "foo", thing: {value: "BAD"}) {
      name
      value
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message:
                    "Argument \"thing\" has invalid value {value: \"BAD\"}.\nIn field \"value\": Expected type \"Int\", found \"BAD\".",
                  locations: [%{column: 33, line: 2}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
