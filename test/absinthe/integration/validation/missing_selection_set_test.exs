defmodule Elixir.Absinthe.Integration.Validation.MissingSelectionSetTest do
  use Absinthe.Case, async: true

  @query """
  query {
    things
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message:
                    "Field \"things\" of type \"[Thing]\" must have a selection of subfields. Did you mean \"things { ... }\"?",
                  locations: [%{column: 3, line: 2}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
