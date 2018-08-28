defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Enum.LiteralTest do
  use ExUnit.Case, async: true

  @query """
  query {
    red: info(channel: RED) {
      name
      value
    }
    green: info(channel: GREEN) {
      name
      value
    }
    blue: info(channel: BLUE) {
      name
      value
    }
    puce: info(channel: PUCE) {
      name
      value
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "blue" => %{"name" => "BLUE", "value" => 300},
                "green" => %{"name" => "GREEN", "value" => 200},
                "puce" => %{"name" => "PUCE", "value" => -100},
                "red" => %{"name" => "RED", "value" => 100}
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ColorSchema, [])
  end
end
