defmodule Elixir.Absinthe.Integration.Validation.CyclesTest do
  use Absinthe.Case, async: true

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
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end

  @query """
  query Foo {
    ...Bar
  }
  fragment Bar on RootQueryType {
    version
    ...Foo
  }
  """

  test "does not choke on unknown fragments" do
    assert {:ok,
            %{
              errors: [
                %{
                  message: "Unknown fragment \"Foo\"",
                  locations: [%{column: 3, line: 6}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
