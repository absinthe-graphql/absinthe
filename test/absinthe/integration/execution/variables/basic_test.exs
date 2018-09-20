defmodule Elixir.Absinthe.Integration.Execution.Variables.BasicTest do
  use ExUnit.Case, async: true

  @query """
  query ($thingId: String!) {
    thing(id: $thingId) {
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"thing" => %{"name" => "Bar"}}}} ==
             Absinthe.run(
               @query,
               Absinthe.Fixtures.ThingsSchema,
               variables: %{"thingId" => "bar"}
             )
  end
end
