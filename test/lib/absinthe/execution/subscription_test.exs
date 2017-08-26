defmodule Absinthe.Execution.SubscriptionTest do
  use Absinthe.Case, async: true

  defmodule PubSub do
    @behaviour Absinthe.Subscription.Pubsub

    def start_link() do
      Registry.start_link(:unique, __MODULE__)
    end

    def subscribe(topic) do
      Registry.register(__MODULE__, topic, [])
      :ok
    end

    def publish_subscription(topic, data) do
      message = %{
        topic: topic,
        event: "subscription:data",
        result: data,
      }

      Registry.dispatch(__MODULE__, topic, fn entries ->
        for {pid, _} <- entries, do: send(pid, {:broadcast, message})
      end)
    end

    def publish_mutation(_proxy_topic, _mutation_result, _subscribed_fields) do
      # this pubsub is local and doesn't support clusters
      :ok
    end
  end

  defmodule Schema do
    use Absinthe.Schema

    query do
      #Query type must exist
    end

    subscription do
      field :thing, :string do
        arg :client_id, non_null(:id)

        config fn
          _args, %{context: %{authorized: false}} ->
            {:error, "unauthorized"}
          args, _ ->
            {
              :ok,
              topic: args.client_id,
            }
        end

      end
    end

  end

  setup_all do
    {:ok, _} = PubSub.start_link()
    {:ok, _} = Absinthe.Subscription.start_link(PubSub)
    :ok
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId)
  }
  """
  it "can subscribe the current process" do
    client_id = "abc"
    assert {:ok, %{"subscribed" => topic}} = run(@query, Schema, variables: %{"clientId" => client_id}, context: %{pubsub: PubSub})
    PubSub.subscribe(topic)
    Absinthe.Subscription.publish(PubSub, "foo", thing: client_id)

    assert_receive({:broadcast, msg})

    assert %{
      event: "subscription:data",
      result: %{data: %{"thing" => "foo"}},
      topic: topic
    } == msg
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId, extra: 1)
  }
  """
  it "can return errors properly" do
    assert {
      :ok,
      %{errors: [%{locations: [%{column: 0, line: 2}],
        message: "Unknown argument \"extra\" on field \"thing\" of type \"RootSubscriptionType\"."}]}
    } == run(@query, Schema, variables: %{"clientId" => "abc"}, context: %{pubsub: PubSub})
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId)
  }
  """
  it "can return an error tuple from the topic function" do
    assert {:error, "unauthorized"} == run(@query, Schema, variables: %{"clientId" => "abc"}, context: %{pubsub: PubSub, authorized: false})
  end

end
