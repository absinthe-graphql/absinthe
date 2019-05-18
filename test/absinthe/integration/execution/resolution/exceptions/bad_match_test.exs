defmodule Elixir.Absinthe.Integration.Execution.Resolution.Exceptions.BadMatchTest do
  use Absinthe.Case, async: true

  @query """
  query {
    badResolution {
      name
    }
  }
  """

  test "scenario #1" do
    assert_raise(Absinthe.ExecutionError, fn ->
      Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
    end)
  end
end
