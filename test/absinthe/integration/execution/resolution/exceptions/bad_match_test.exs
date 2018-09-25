defmodule Elixir.Absinthe.Integration.Execution.Resolution.Exceptions.BadMatchTest do
  use ExUnit.Case, async: true

  @query """
  query {
    badResolution {
      name
    }
  }
  """

  test "scenario #1" do
    assert_raise(Absinthe.ExecutionError, fn ->
      Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, [])
    end)
  end
end
