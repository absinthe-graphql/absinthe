defmodule Absinthe.Execution.SubscriptionTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    subscription do
      field :thing, :string do
        arg :client_id, non_null(:id)
        resolve fn
          %{client_id: id}, _ ->
            {:ok, "subscribed-#{id}"}
        end
      end
    end

  end

  describe "subscriptions" do

    @query """
    subscription SubscribeToThing($clientID: ID!) {
      thing(clientId: $clientId)
    }
    """
    it "can be executed" do
      assert {:ok, %{data: %{"thing" => "subscribed-abc"}}} == Absinthe.run(@query, Schema, variables: %{"clientId" => "abc"})
    end
  end

end
