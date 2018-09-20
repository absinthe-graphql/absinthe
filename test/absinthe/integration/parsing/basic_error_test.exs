defmodule Elixir.Absinthe.Integration.Parsing.BasicErrorTest do
  use ExUnit.Case, async: true

  @query """
  {
    thing(id: "foo") {}{ name }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{message: "syntax error before: '}'", locations: [%{column: 21, line: 2}]}
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
  end
end
