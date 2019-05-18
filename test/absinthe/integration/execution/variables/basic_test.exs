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
    for schema <- schema_implementations(Absinthe.Fixtures.Things) do
      assert {:ok, %{data: %{"thing" => %{"name" => "Bar"}}}} ==
        Absinthe.run(
          @query,
          schema,
          variables: %{"thingId" => "bar"}
        )
    end
  end

  defp schema_implementations(base) do
    [
      Module.safe_concat(base, MacroSchema),
      Module.safe_concat(base, SDLSchema)
    ]
  end

end
