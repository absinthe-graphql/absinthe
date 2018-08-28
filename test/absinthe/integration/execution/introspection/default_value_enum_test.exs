defmodule Elixir.Absinthe.Integration.Execution.Introspection.DefaultValueEnumTest do
  use ExUnit.Case, async: true

  @query """
  query {
    __type(name: "ChannelInput") {
      name
      inputFields {
        name
        defaultValue
      }
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "__type" => %{
                  "inputFields" => [%{"defaultValue" => "RED", "name" => "channel"}],
                  "name" => "ChannelInput"
                }
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ColorSchema, [])
  end
end
