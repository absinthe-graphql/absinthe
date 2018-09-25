defmodule Elixir.Absinthe.Integration.Execution.Introspection.SubscriptionTypeTest do
  use ExUnit.Case, async: true

  @query """
  query { __schema { subscriptionType { name kind } } }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "__schema" => %{
                  "subscriptionType" => %{"kind" => "OBJECT", "name" => "RootSubscriptionType"}
                }
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
