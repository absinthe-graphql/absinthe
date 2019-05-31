defmodule Elixir.Absinthe.Integration.Validation.ExtraArgumentsTest do
  use Absinthe.Case, async: true

  @query """
  query {
    thing(id: "foo", extra: "dunno") {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message:
                    "Unknown argument \"extra\" on field \"thing\" of type \"RootQueryType\".",
                  locations: [%{column: 20, line: 2}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
