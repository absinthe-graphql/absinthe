defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Null.LiteralToTypeNonNull_TTest do
  use ExUnit.Case, async: true

  @query """
  # Schema: ObjectTimesSchema
  query {
    times: objTimes(input: {base: null})
  }
  """

  test "scenario #1" do
    assert {:ok, %{errors: [%{message: "Argument \"input\" has invalid value {base: null}.\nIn field \"base\": Expected type \"Int!\", found null."}]}} == Absinthe.run(@query, Absinthe.Fixtures.ObjectTimesSchema, [])
  end
end
