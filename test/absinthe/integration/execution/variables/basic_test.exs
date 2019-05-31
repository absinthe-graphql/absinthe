defmodule Elixir.Absinthe.Integration.Execution.Variables.BasicTest do
  use Absinthe.Case, async: true

  @query """
  query ($thingId: String!) {
    thing(id: $thingId) {
      name
    }
  }
  """

  test "scenario #1" do
    for schema <- schema_implementations(Absinthe.Fixtures.Things) do
      assert {:ok, %{data: %{"thing" => %{"name" => "Bar"}}}} ==
               Absinthe.run(
                 @query,
                 schema,
                 variables: %{"thingId" => "bar"}
               )
    end
  end
end
