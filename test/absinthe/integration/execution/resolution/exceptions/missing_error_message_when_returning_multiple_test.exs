defmodule Elixir.Absinthe.Integration.Execution.Resolution.Exceptions.MissingErrorMessageWhenReturningMultipleTest do
  use Absinthe.Case, async: true

  @query """
  mutation { failingThing(type: MULTIPLE_WITHOUT_MESSAGE) { name } }
  """

  test "scenario #1" do
    assert_raise(Absinthe.ExecutionError, fn ->
      Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
    end)
  end
end
