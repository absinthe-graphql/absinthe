defmodule Absinthe.Execution.SubscriptionTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  defmodule PubSub do
    @behaviour Absinthe.Subscription.Pubsub

    def start_link() do
      Registry.start_link(keys: :unique, name: __MODULE__)
    end

    def node_name() do
      node()
    end

    def subscribe(topic) do
      Registry.register(__MODULE__, topic, [])
      :ok
    end

    def publish_subscription(topic, data) do
      message = %{
        topic: topic,
        event: "subscription:data",
        result: data
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
      # Query type must exist
    end

    object :user do
      field :id, :id
      field :name, :string

      field :group, :group do
        resolve fn user, _, %{context: %{test_pid: pid}} ->
          batch({__MODULE__, :batch_get_group, pid}, nil, fn _results ->
            {:ok, user.group}
          end)
        end
      end
    end

    object :group do
      field :name, :string
    end

    def batch_get_group(test_pid, _) do
      # send a message to the test process every time we access this function.
      # if batching is working properly, it should only happen once.
      send(test_pid, :batch_get_group)
      %{}
    end

    subscription do
      field :raises, :string do
        config fn _, _ ->
          {:ok, topic: "*"}
        end

        resolve fn _, _, _ ->
          raise "boom"
        end
      end

      field :user, :user do
        arg :id, :id

        config fn args, _ ->
          {:ok, topic: args[:id] || "*"}
        end

        trigger :update_user,
          topic: fn user ->
            [user.id, "*"]
          end
      end

      field :thing, :string do
        arg :client_id, non_null(:id)

        config fn
          _args, %{context: %{authorized: false}} ->
            {:error, "unauthorized"}

          args, _ ->
            {
              :ok,
              topic: args.client_id
            }
        end
      end

      field :multiple_topics, :string do
        config fn _, _ ->
          {:ok, topic: ["topic_1", "topic_2", "topic_3"]}
        end
      end
    end

    mutation do
      field :update_user, :user do
        arg :id, non_null(:id)

        resolve fn _, %{id: id}, _ ->
          {:ok, %{id: id, name: "foo"}}
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
  test "can subscribe the current process" do
    client_id = "abc"

    assert {:ok, %{"subscribed" => topic}} =
             run(
               @query,
               Schema,
               variables: %{"clientId" => client_id},
               context: %{pubsub: PubSub}
             )

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
    thing(clientId: $clientId)
  }
  """
  test "can unsubscribe the current process" do
    client_id = "abc"

    assert {:ok, %{"subscribed" => topic}} =
             run(
               @query,
               Schema,
               variables: %{"clientId" => client_id},
               context: %{pubsub: PubSub}
             )

    Absinthe.Subscription.unsubscribe(PubSub, topic)

    Absinthe.Subscription.publish(PubSub, "foo", thing: client_id)

    refute_receive({:broadcast, _})
  end

  @query """
  subscription {
    multipleTopics
  }
  """
  test "schema can provide multiple topics to subscribe to" do
    assert {:ok, %{"subscribed" => topic}} =
             run(
               @query,
               Schema,
               variables: %{},
               context: %{pubsub: PubSub}
             )

    msg = %{
      event: "subscription:data",
      result: %{data: %{"multipleTopics" => "foo"}},
      topic: topic
    }

    Absinthe.Subscription.publish(PubSub, "foo", multiple_topics: "topic_1")

    assert_receive({:broadcast, ^msg})

    Absinthe.Subscription.publish(PubSub, "foo", multiple_topics: "topic_2")

    assert_receive({:broadcast, ^msg})

    Absinthe.Subscription.publish(PubSub, "foo", multiple_topics: "topic_3")

    assert_receive({:broadcast, ^msg})
  end

  @query """
  subscription {
    multipleTopics
  }
  """
  test "unsubscription works when multiple topics are provided" do
    assert {:ok, %{"subscribed" => topic}} =
             run(
               @query,
               Schema,
               variables: %{},
               context: %{pubsub: PubSub}
             )

    Absinthe.Subscription.unsubscribe(PubSub, topic)

    Absinthe.Subscription.publish(PubSub, "foo", multiple_topics: "topic_1")

    refute_receive({:broadcast, _})

    Absinthe.Subscription.publish(PubSub, "foo", multiple_topics: "topic_2")

    refute_receive({:broadcast, _})

    Absinthe.Subscription.publish(PubSub, "foo", multiple_topics: "topic_3")

    refute_receive({:broadcast, _})
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId, extra: 1)
  }
  """
  test "can return errors properly" do
    assert {
             :ok,
             %{
               errors: [
                 %{
                   locations: [%{column: 30, line: 2}],
                   message:
                     "Unknown argument \"extra\" on field \"thing\" of type \"RootSubscriptionType\"."
                 }
               ]
             }
           } == run(@query, Schema, variables: %{"clientId" => "abc"}, context: %{pubsub: PubSub})
  end

  @query """
  subscription ($userId: ID!) {
    user(id: $userId) { id name }
  }
  """
  test "subscription triggers work" do
    id = "1"

    assert {:ok, %{"subscribed" => topic}} =
             run(
               @query,
               Schema,
               variables: %{"userId" => id},
               context: %{pubsub: PubSub}
             )

    mutation = """
    mutation ($userId: ID!) {
      updateUser(id: $userId) { id name }
    }
    """

    assert {:ok, %{data: _}} =
             run(mutation, Schema,
               variables: %{"userId" => id},
               context: %{pubsub: PubSub}
             )

    assert_receive({:broadcast, msg})

    assert %{
             event: "subscription:data",
             result: %{data: %{"user" => %{"id" => "1", "name" => "foo"}}},
             topic: topic
           } == msg
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId)
  }
  """
  test "can return an error tuple from the topic function" do
    assert {:ok, %{errors: [%{locations: [%{column: 3, line: 2}], message: "unauthorized"}]}} ==
             run(
               @query,
               Schema,
               variables: %{"clientId" => "abc"},
               context: %{pubsub: PubSub, authorized: false}
             )
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId)
  }
  """
  test "stringifies topics" do
    assert {:ok, %{"subscribed" => topic}} =
             run(@query, Schema, variables: %{"clientId" => "1"}, context: %{pubsub: PubSub})

    Absinthe.Subscription.publish(PubSub, "foo", thing: 1)

    assert_receive({:broadcast, msg})

    assert %{
             event: "subscription:data",
             result: %{data: %{"thing" => "foo"}},
             topic: topic
           } == msg
  end

  test "isn't tripped up if one of the subscription docs raises" do
    assert {:ok, %{"subscribed" => _}} = run("subscription { raises }", Schema)
    assert {:ok, %{"subscribed" => topic}} = run("subscription { thing(clientId: \"*\")}", Schema)

    error_log =
      capture_log(fn ->
        Absinthe.Subscription.publish(PubSub, "foo", raises: "*", thing: "*")

        assert_receive({:broadcast, msg})

        assert %{
                 event: "subscription:data",
                 result: %{data: %{"thing" => "foo"}},
                 topic: topic
               } == msg
      end)

    assert String.contains?(error_log, "boom")
  end

  test "different subscription docs are batched together" do
    opts = [context: %{test_pid: self()}]

    assert {:ok, %{"subscribed" => doc1}} =
             run("subscription { user { group { name } id} }", Schema, opts)

    # different docs required for test, otherwise they get deduplicated from the start
    assert {:ok, %{"subscribed" => doc2}} =
             run("subscription { user { group { name } id name} }", Schema, opts)

    user = %{id: "1", name: "Alicia", group: %{name: "Elixir Users"}}

    Absinthe.Subscription.publish(PubSub, user, user: ["*", user.id])

    assert_receive({:broadcast, %{topic: ^doc1, result: %{data: _}}})
    assert_receive({:broadcast, %{topic: ^doc2, result: %{data: %{"user" => user}}}})

    assert user["group"]["name"] == "Elixir Users"

    # we should get this just once due to batching
    assert_receive(:batch_get_group)
    refute_receive(:batch_get_group)
  end

  test "subscription docs with different contexts don't leak context" do
    ctx1 = %{test_pid: self(), user: 1}

    assert {:ok, %{"subscribed" => doc1}} =
             run("subscription { user { group { name } id} }", Schema, context: ctx1)

    ctx2 = %{test_pid: self(), user: 2}
    # different docs required for test, otherwise they get deduplicated from the start
    assert {:ok, %{"subscribed" => doc2}} =
             run("subscription { user { group { name } id name} }", Schema, context: ctx2)

    user = %{id: "1", name: "Alicia", group: %{name: "Elixir Users"}}

    Absinthe.Subscription.publish(PubSub, user, user: ["*", user.id])

    assert_receive({:broadcast, %{topic: ^doc1, result: %{data: _}}})
    assert_receive({:broadcast, %{topic: ^doc2, result: %{data: %{"user" => user}}}})

    assert user["group"]["name"] == "Elixir Users"

    # we should get this twice since the different contexts prevent batching.
    assert_receive(:batch_get_group)
    assert_receive(:batch_get_group)
  end

  defp run(query, schema, opts \\ []) do
    opts = Keyword.update(opts, :context, %{pubsub: PubSub}, &Map.put(&1, :pubsub, PubSub))

    case Absinthe.run(query, schema, opts) do
      {:ok, %{"subscribed" => topic}} = val ->
        PubSub.subscribe(topic)
        val

      val ->
        val
    end
  end
end
