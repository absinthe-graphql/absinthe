defmodule Elixir.Absinthe.Integration.Validation.CyclesTest do
  use ExUnit.Case, async: true

  @query """
  query Foo {
    name
  }
  fragment Foo on Blag {
    name
    ...Bar
  }
  fragment Bar on Blah {
    age
    ...Foo
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: "Cannot spread fragment \"Foo\" within itself via \"Bar\", \"Foo\".",
                  locations: [%{column: 1, line: 4}]
                },
                %{
                  message: "Cannot spread fragment \"Bar\" within itself via \"Foo\", \"Bar\".",
                  locations: [%{column: 1, line: 8}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
