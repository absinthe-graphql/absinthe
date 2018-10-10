defmodule Elixir.Absinthe.Integration.Execution.RootValueTest do
  use ExUnit.Case, async: true

  @query """
  query { version }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"version" => "0.0.1"}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ThingsSchema, root_value: %{version: "0.0.1"})
  end
end
