defmodule Elixir.Absinthe.Integration.Validation.UnknownArgForListMemberFieldTest do
  use Absinthe.Case, async: true

  @query """
  query {
    things {
      id(x: 1)
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: "Unknown argument \"x\" on field \"id\" of type \"Thing\".",
                  locations: [%{column: 8, line: 3}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
