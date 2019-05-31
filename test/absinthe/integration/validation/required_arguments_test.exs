defmodule Elixir.Absinthe.Integration.Validation.RequiredArgumentsTest do
  use Absinthe.Case, async: true

  @query """
  query { thing { name } }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: "In argument \"id\": Expected type \"String!\", found null.",
                  locations: [%{column: 9, line: 1}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
