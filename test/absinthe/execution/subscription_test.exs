defmodule Absinthe.Execution.SubscriptionTest do
  use Absinthe.Case

  import ExUnit.CaptureLog

  defmodule ResultPhase do
    @moduledoc false

    alias Absinthe.Blueprint
    use Absinthe.Phase

    def run(%Blueprint{} = bp, _options \\ []) do
      result = Map.merge(bp.result, process(bp))
      {:ok, %{bp | result: result}}
    end

    defp process(blueprint) do
      data = data(blueprint.execution.result)
      %{data: data}
    end

    defp data(%{value: value}), do: value

    defp data(%{fields: []} = result) do
      result.root_value
    end

    defp data(%{fields: fields, emitter: emitter, root_value: root_value}) do
      with %{put: _} <- emitter.flags,
           true <- is_map(root_value) do
        data = field_data(fields)
        Map.merge(root_value, data)
      else
        _ ->
          field_data(fields)
      end
    end

    defp field_data(fields, acc \\ [])
    defp field_data([], acc), do: Map.new(acc)

    defp field_data([field | fields], acc) do
      value = data(field)
      field_data(fields, [{String.to_existing_atom(field.emitter.name), value} | acc])
    end
  end

  defmodule PubSub do
    @behaviour Absinthe.Subscription.Pubsub

    def start_link() do
      Registry.start_link(keys: :duplicate, name: __MODULE__)
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

  defmodule PubSubWithDocsetRunner do
    @behaviour Absinthe.Subscription.Pubsub

    def start_link() do
      Registry.start_link(keys: :duplicate, name: __MODULE__)
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

    def run_docset(pubsub, docs_and_topics, _mutation_result) do
      for {topic, _key_strategy, _doc} <- docs_and_topics do
        # publish mutation results to topic
        pubsub.publish_subscription(topic, %{data: %{runner: "calls the custom docset runner"}})
      end
    end
  end

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    object :user do
      field :id, :id
      field :name, :string
      field :version, :integer

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

      field :other_user, :user do
        arg :id, :id

        config fn
          args, %{context: %{context_id: context_id, document_id: document_id}} ->
            {:ok, topic: args[:id] || "*", context_id: context_id, document_id: document_id}

          args, %{context: %{context_id: context_id}} ->
            {:ok, topic: args[:id] || "*", context_id: context_id}
        end
      end

      field :relies_on_document, :string do
        config fn _, %{document: %Absinthe.Blueprint{} = document} ->
          %{type: :subscription, name: op_name} = Absinthe.Blueprint.current_operation(document)
          {:ok, topic: "*", context_id: "*", document_id: op_name}
        end
      end

      field :config_error, :string do
        config fn _, _ ->
          {:error, "failed"}
        end
      end

      field :config_error_with_map, :string do
        config fn _, _ ->
          {:error, %{message: "failed", extensions: %{code: "FAILED"}}}
        end
      end

      field :prime, :user do
        arg :client_id, non_null(:id)
        arg :prime_data, list_of(:string)

        config fn args, _ ->
          {
            :ok,
            topic: args.client_id,
            prime: fn %{context: %{prime_id: prime_id}} ->
              {:ok, Enum.map(args.prime_data, &%{id: prime_id, name: &1})}
            end
          }
        end
      end

      field :ordinal, :user do
        arg :client_id, non_null(:id)

        config fn args, _ ->
          {
            :ok,
            topic: args.client_id, ordinal: fn %{version: version} -> version end
          }
        end
      end

      field :prime_ordinal, :user do
        arg :client_id, non_null(:id)
        arg :prime_data, list_of(:string)

        config fn args, _ ->
          {
            :ok,
            topic: args.client_id,
            prime: fn _ ->
              {:ok, [%{name: "first_user", version: 1}, %{name: "second_user", version: 2}]}
            end,
            ordinal: fn %{version: version} -> version end
          }
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

    {:ok, _} = PubSubWithDocsetRunner.start_link()
    {:ok, _} = Absinthe.Subscription.start_link(PubSubWithDocsetRunner)
    :ok
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId)
  }
  """
  test "should use result_phase from main pipeline" do
    client_id = "abc"

    assert {:ok, %{"subscribed" => topic}} =
             run_subscription(
               @query,
               Schema,
               variables: %{"clientId" => client_id},
               context: %{pubsub: PubSub},
               result_phase: ResultPhase
             )

    Absinthe.Subscription.publish(PubSub, %{foo: "bar"}, thing: client_id)

    assert_receive({:broadcast, msg})

    assert %{
             event: "subscription:data",
             result: %{data: %{thing: %{foo: "bar"}}},
             topic: topic
           } == msg
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId)
  }
  """
  test "can subscribe the current process" do
    client_id = "abc"

    assert {:ok, %{"subscribed" => topic}} =
             run_subscription(
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
             run_subscription(
               @query,
               Schema,
               variables: %{"clientId" => client_id},
               context: %{pubsub: PubSub}
             )

    Absinthe.Subscription.unsubscribe(PubSub, topic)

    Absinthe.Subscription.publish(PubSub, "foo", thing: client_id)

    refute_receive({:broadcast, _})
  end

  test "can unsubscribe from duplicate subscriptions individually" do
    client_id = "abc"

    assert {:ok, %{"subscribed" => topic1}} =
             run_subscription(
               @query,
               Schema,
               variables: %{"clientId" => client_id},
               context: %{pubsub: PubSub}
             )

    assert {:ok, %{"subscribed" => topic2}} =
             run_subscription(
               @query,
               Schema,
               variables: %{"clientId" => client_id},
               context: %{pubsub: PubSub}
             )

    Absinthe.Subscription.publish(PubSub, "foo", thing: client_id)
    assert_receive({:broadcast, a})
    assert_receive({:broadcast, b})
    doc_ids = Enum.map([a, b], & &1.topic)
    assert topic1 in doc_ids
    assert topic2 in doc_ids

    Absinthe.Subscription.unsubscribe(PubSub, topic1)
    Absinthe.Subscription.publish(PubSub, "bar", thing: client_id)
    assert_receive({:broadcast, a})
    refute_receive({:broadcast, _})
    assert topic2 == a.topic
  end

  @query """
  subscription {
    multipleTopics
  }
  """
  test "schema can provide multiple topics to subscribe to" do
    assert {:ok, %{"subscribed" => topic}} =
             run_subscription(
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
             run_subscription(
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
           } ==
             run_subscription(@query, Schema,
               variables: %{"clientId" => "abc"},
               context: %{pubsub: PubSub}
             )
  end

  @query """
  subscription ($userId: ID!) {
    user(id: $userId) { id name }
  }
  """
  test "subscription triggers work" do
    id = "1"

    assert {:ok, %{"subscribed" => topic}} =
             run_subscription(
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
             run_subscription(mutation, Schema,
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
             run_subscription(
               @query,
               Schema,
               variables: %{"clientId" => "abc"},
               context: %{pubsub: PubSub, authorized: false}
             )
  end

  test "fires telemetry events when subscription config returns error", %{test: test} do
    :ok =
      :telemetry.attach_many(
        "#{test}",
        [
          [:absinthe, :execute, :operation, :start],
          [:absinthe, :execute, :operation, :stop]
        ],
        &Absinthe.TestTelemetryHelper.send_to_pid/4,
        %{pid: self()}
      )

    assert {:ok, %{errors: [%{locations: [%{column: 3, line: 2}], message: "unauthorized"}]}} ==
             run_subscription(
               @query,
               Schema,
               variables: %{"clientId" => "abc"},
               context: %{pubsub: PubSub, authorized: false}
             )

    assert_received {:telemetry_event, {[:absinthe, :execute, :operation, :start], _, _, _}}

    assert_received {:telemetry_event, {[:absinthe, :execute, :operation, :stop], _, _, _}}
  end

  @query """
  subscription Example {
    reliesOnDocument
  }
  """
  test "topic function receives a document" do
    assert {:ok, %{"subscribed" => _topic}} =
             run_subscription(@query, Schema, context: %{pubsub: PubSub})
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId)
  }
  """
  test "stringifies topics" do
    assert {:ok, %{"subscribed" => topic}} =
             run_subscription(@query, Schema,
               variables: %{"clientId" => "1"},
               context: %{pubsub: PubSub}
             )

    Absinthe.Subscription.publish(PubSub, "foo", thing: 1)

    assert_receive({:broadcast, msg})

    assert %{
             event: "subscription:data",
             result: %{data: %{"thing" => "foo"}},
             topic: topic
           } == msg
  end

  test "isn't tripped up if one of the subscription docs raises" do
    assert {:ok, %{"subscribed" => _}} = run_subscription("subscription { raises }", Schema)

    assert {:ok, %{"subscribed" => topic}} =
             run_subscription("subscription { thing(clientId: \"*\")}", Schema)

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

  @tag :pending
  test "different subscription docs are batched together" do
    opts = [context: %{test_pid: self()}]

    assert {:ok, %{"subscribed" => doc1}} =
             run_subscription("subscription { user { group { name } id} }", Schema, opts)

    # different docs required for test, otherwise they get deduplicated from the start
    assert {:ok, %{"subscribed" => doc2}} =
             run_subscription("subscription { user { group { name } id name} }", Schema, opts)

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
             run_subscription("subscription { user { group { name } id} }", Schema, context: ctx1)

    ctx2 = %{test_pid: self(), user: 2}
    # different docs required for test, otherwise they get deduplicated from the start
    assert {:ok, %{"subscribed" => doc2}} =
             run_subscription("subscription { user { group { name } id name} }", Schema,
               context: ctx2
             )

    user = %{id: "1", name: "Alicia", group: %{name: "Elixir Users"}}

    Absinthe.Subscription.publish(PubSub, user, user: ["*", user.id])

    assert_receive({:broadcast, %{topic: ^doc1, result: %{data: _}}})
    assert_receive({:broadcast, %{topic: ^doc2, result: %{data: %{"user" => user}}}})

    assert user["group"]["name"] == "Elixir Users"

    # we should get this twice since the different contexts prevent batching.
    assert_receive(:batch_get_group)
    assert_receive(:batch_get_group)
  end

  @query """
  subscription Example {
    configError
  }
  """
  test "config errors" do
    assert {:ok, %{errors: [%{message: "failed"}]}} =
             run_subscription(
               @query,
               Schema,
               variables: %{},
               context: %{pubsub: PubSub}
             )
  end

  @query """
  subscription Example {
    configErrorWithMap
  }
  """
  test "config errors with a map" do
    assert {:ok, %{errors: [%{message: "failed", extensions: %{code: "FAILED"}}]}} =
             run_subscription(
               @query,
               Schema,
               variables: %{},
               context: %{pubsub: PubSub}
             )
  end

  describe "subscription_ids" do
    @query """
    subscription {
      otherUser { id }
    }
    """
    test "subscriptions with the same context_id and same source document have the same subscription_id" do
      assert {:ok, %{"subscribed" => doc1}} =
               run_subscription(@query, Schema, context: %{context_id: "logged-in"})

      assert {:ok, %{"subscribed" => doc2}} =
               run_subscription(@query, Schema, context: %{context_id: "logged-in"})

      assert doc1 == doc2
    end

    @query """
    subscription {
      otherUser { id }
    }
    """
    test "subscriptions with different context_id but the same source document have different subscription_ids" do
      assert {:ok, %{"subscribed" => doc1}} =
               run_subscription(@query, Schema, context: %{context_id: "logged-in"})

      assert {:ok, %{"subscribed" => doc2}} =
               run_subscription(@query, Schema, context: %{context_id: "not-logged-in"})

      assert doc1 != doc2
    end

    test "subscriptions with same context_id but different source document have different subscription_ids" do
      assert {:ok, %{"subscribed" => doc1}} =
               run_subscription("subscription { otherUser { id name } }", Schema,
                 context: %{context_id: "logged-in"}
               )

      assert {:ok, %{"subscribed" => doc2}} =
               run_subscription("subscription { otherUser { id } }", Schema,
                 context: %{context_id: "logged-in"}
               )

      assert doc1 != doc2
    end

    test "subscriptions with different context_id and different source document have different subscription_ids" do
      assert {:ok, %{"subscribed" => doc1}} =
               run_subscription("subscription { otherUser { id name } }", Schema,
                 context: %{context_id: "logged-in"}
               )

      assert {:ok, %{"subscribed" => doc2}} =
               run_subscription("subscription { otherUser { id } }", Schema,
                 context: %{context_id: "not-logged-in"}
               )

      assert doc1 != doc2
    end

    @query """
    subscription($id: ID!) { otherUser(id: $id) { id } }
    """
    test "subscriptions with the same variables & document have the same subscription_ids" do
      assert {:ok, %{"subscribed" => doc1}} =
               run_subscription(@query, Schema,
                 variables: %{"id" => "123"},
                 context: %{context_id: "logged-in"}
               )

      assert {:ok, %{"subscribed" => doc2}} =
               run_subscription(@query, Schema,
                 variables: %{"id" => "123"},
                 context: %{context_id: "logged-in"}
               )

      assert doc1 == doc2
    end

    @query """
    subscription($id: ID!) { otherUser(id: $id) { id } }
    """
    test "subscriptions with different variables but same document have different subscription_ids" do
      assert {:ok, %{"subscribed" => doc1}} =
               run_subscription(@query, Schema,
                 variables: %{"id" => "123"},
                 context: %{context_id: "logged-in"}
               )

      assert {:ok, %{"subscribed" => doc2}} =
               run_subscription(@query, Schema,
                 variables: %{"id" => "456"},
                 context: %{context_id: "logged-in"}
               )

      assert doc1 != doc2
    end

    test "document_id can be provided to override the default logic for deriving document_id" do
      assert {:ok, %{"subscribed" => doc1}} =
               run_subscription("subscription { otherUser { id name } }", Schema,
                 context: %{context_id: "logged-in", document_id: "abcdef"}
               )

      assert {:ok, %{"subscribed" => doc2}} =
               run_subscription("subscription { otherUser { name id } }", Schema,
                 context: %{context_id: "logged-in", document_id: "abcdef"}
               )

      assert doc1 == doc2
    end
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId)
  }
  """
  test "subscription executes telemetry events", context do
    client_id = "abc"

    :telemetry.attach_many(
      context.test,
      [
        [:absinthe, :execute, :operation, :start],
        [:absinthe, :execute, :operation, :stop],
        [:absinthe, :subscription, :publish, :start],
        [:absinthe, :subscription, :publish, :stop]
      ],
      &Absinthe.TestTelemetryHelper.send_to_pid/4,
      %{}
    )

    assert {:ok, %{"subscribed" => topic}} =
             run_subscription(
               @query,
               Schema,
               variables: %{"clientId" => client_id},
               context: %{pubsub: PubSub}
             )

    assert_receive {:telemetry_event,
                    {[:absinthe, :execute, :operation, :start], measurements, %{id: id}, _config}}

    assert System.convert_time_unit(measurements[:system_time], :native, :millisecond)

    assert_receive {:telemetry_event,
                    {[:absinthe, :execute, :operation, :stop], _, %{id: ^id}, _config}}

    Absinthe.Subscription.publish(PubSub, "foo", thing: client_id)
    assert_receive({:broadcast, msg})

    assert %{
             event: "subscription:data",
             result: %{data: %{"thing" => "foo"}},
             topic: topic
           } == msg

    # Subscription events
    assert_receive {:telemetry_event,
                    {[:absinthe, :subscription, :publish, :start], _, %{id: id}, _config}}

    assert_receive {:telemetry_event,
                    {[:absinthe, :subscription, :publish, :stop], _, %{id: ^id}, _config}}

    :telemetry.detach(context.test)
  end

  @query """
  subscription {
    otherUser { id }
  }
  """
  test "de-duplicates pushes to the same context" do
    documents =
      Enum.map(1..5, fn _index ->
        {:ok, doc} = run_subscription(@query, Schema, context: %{context_id: "global"})
        doc
      end)

    # assert that all documents are the same
    assert [document] = Enum.dedup(documents)

    Absinthe.Subscription.publish(
      PubSub,
      %{id: "global_user_id"},
      other_user: "*"
    )

    topic_id = document["subscribed"]

    for _i <- 1..5 do
      assert_receive(
        {:broadcast,
         %{
           event: "subscription:data",
           result: %{data: %{"otherUser" => %{"id" => "global_user_id"}}},
           topic: ^topic_id
         }}
      )
    end

    refute_receive({:broadcast, _})
  end

  @query """
  subscription ($userId: ID!) {
    user(id: $userId) { id name }
  }
  """
  test "calls the optional run_docset callback if supplied" do
    id = "1"

    assert {:ok, %{"subscribed" => topic}} =
             run_subscription(
               @query,
               Schema,
               variables: %{"userId" => id},
               context: %{pubsub: PubSubWithDocsetRunner}
             )

    mutation = """
    mutation ($userId: ID!) {
      updateUser(id: $userId) { id name }
    }
    """

    assert {:ok, %{data: _}} =
             run_subscription(mutation, Schema,
               variables: %{"userId" => id},
               context: %{pubsub: PubSubWithDocsetRunner}
             )

    assert_receive({:broadcast, msg})

    assert %{
             event: "subscription:data",
             result: %{data: %{runner: "calls the custom docset runner"}},
             topic: topic
           } == msg
  end

  @query """
  subscription ($clientId: ID!, $primeData: [String]) {
    prime(clientId: $clientId, primeData: $primeData) {
      id
      name
    }
  }
  """
  test "subscription with priming" do
    client_id = "abc"
    prime_data = ["name1", "name2"]

    assert {:more, %{"subscribed" => _topic, continuations: continuations}} =
             run_subscription(
               @query,
               Schema,
               variables: %{
                 "primeData" => prime_data,
                 "clientId" => client_id
               },
               context: %{prime_id: "test_prime_id"}
             )

    assert {:more,
            %{
              data: %{"prime" => %{"id" => "test_prime_id", "name" => "name1"}},
              continuations: continuations
            }} = Absinthe.continue(continuations)

    assert {:ok, %{data: %{"prime" => %{"id" => "test_prime_id", "name" => "name2"}}}} =
             Absinthe.continue(continuations)
  end

  test "continuation with no extra data" do
    client_id = "abc"

    assert {:more, %{"subscribed" => _topic, continuations: continuations}} =
             run_subscription(
               @query,
               Schema,
               variables: %{
                 "primeData" => [],
                 "clientId" => client_id
               },
               context: %{prime_id: "test_prime_id"}
             )

    assert :no_more_results == Absinthe.continue(continuations)
  end

  @query """
  subscription ($clientId: ID!) {
    ordinal(clientId: $clientId) {
      name
    }
  }
  """
  test "subscription with ordinals" do
    client_id = "abc"

    assert {:ok, %{"subscribed" => _topic}} =
             run_subscription(
               @query,
               Schema,
               variables: %{"clientId" => client_id},
               context: %{pubsub: PubSub}
             )

    userv1 = %{id: "1", name: "Alicia", group: %{name: "Elixir Users"}, version: 1}
    userv2 = %{id: "1", name: "Alicia", group: %{name: "Elixir Users"}, version: 2}

    Absinthe.Subscription.publish(PubSub, userv1, ordinal: client_id)
    Absinthe.Subscription.publish(PubSub, userv2, ordinal: client_id)

    assert_receive({:broadcast, msg})
    assert msg.result.ordinal == 1
    assert_receive({:broadcast, msg})
    assert msg.result.ordinal == 2
  end

  @query """
  subscription ($clientId: ID!) {
    primeOrdinal(clientId: $clientId) {
      name
    }
  }
  """
  test "subscription with both priming and ordinals" do
    client_id = "abc"

    assert {:more, %{"subscribed" => _topic, continuations: continuations}} =
             run_subscription(
               @query,
               Schema,
               variables: %{
                 "clientId" => client_id
               }
             )

    assert {:more,
            %{
              data: %{"primeOrdinal" => %{"name" => "first_user"}},
              ordinal: 1,
              continuations: continuations
            }} = Absinthe.continue(continuations)

    assert {:ok, %{data: %{"primeOrdinal" => %{"name" => "second_user"}}, ordinal: 2}} =
             Absinthe.continue(continuations)
  end

  def run_subscription(query, schema, opts \\ []) do
    opts =
      Keyword.update(
        opts,
        :context,
        %{pubsub: PubSub},
        &Map.put(&1, :pubsub, opts[:context][:pubsub] || PubSub)
      )

    case run(query, schema, opts) do
      {response, %{"subscribed" => topic}} = val when response == :ok or response == :more ->
        opts[:context][:pubsub].subscribe(topic)
        val

      val ->
        val
    end
  end
end
