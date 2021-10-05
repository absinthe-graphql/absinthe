defmodule Elixir.Absinthe.Integration.Execution.Introspection.SubscriptionTypeTest do
  use Absinthe.Case, async: true

  @query """
  query { __schema { subscriptionType { name kind } } }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "__schema" => %{
                  "subscriptionType" => %{"kind" => "OBJECT", "name" => "Subscription"}
                }
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
