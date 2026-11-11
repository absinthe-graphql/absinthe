defmodule Absinthe.Subscription.SubscribedTest do
  use Absinthe.Case, async: false

  defmodule PubSub do
    @behaviour Absinthe.Subscription.Pubsub

    def start_link, do: Registry.start_link(keys: :duplicate, name: __MODULE__)
    def node_name, do: node()

    def subscribe(topic) do
      {:ok, _} = Registry.register(__MODULE__, topic, [])
      :ok
    end

    def publish_subscription(_topic, _data), do: :ok
    def publish_mutation(_proxy_topic, _mutation_result, _subscribed_fields), do: :ok
  end

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    subscription do
      field :thing, :string do
        arg :client_id, non_null(:id)

        config fn args, _ -> {:ok, topic: args.client_id} end
      end
    end
  end

  @query """
  subscription ($clientId: ID!) {
    thing(clientId: $clientId)
  }
  """

  setup_all do
    {:ok, _} = PubSub.start_link()
    {:ok, _} = Absinthe.Subscription.start_link(PubSub)
    :ok
  end

  defp subscribe(client_id) do
    assert {:ok, %{"subscribed" => doc_id}} =
             run(@query, Schema,
               variables: %{"clientId" => client_id},
               context: %{pubsub: PubSub}
             )

    doc_id
  end

  describe "subscribed?/3" do
    test "is true for a subscribed field and topic" do
      subscribe("subscribed-1")

      assert Absinthe.Subscription.subscribed?(PubSub, :thing, "subscribed-1")
    end

    test "is false for a topic nobody subscribed to" do
      subscribe("subscribed-2")

      refute Absinthe.Subscription.subscribed?(PubSub, :thing, "unsubscribed-2")
    end

    test "is false for a different field with the same topic" do
      subscribe("subscribed-3")

      refute Absinthe.Subscription.subscribed?(PubSub, :other, "subscribed-3")
    end

    test "stringifies the topic as subscribing does" do
      subscribe("42")

      assert Absinthe.Subscription.subscribed?(PubSub, :thing, 42)
    end

    test "is false after unsubscribing" do
      doc_id = subscribe("subscribed-5")
      assert Absinthe.Subscription.subscribed?(PubSub, :thing, "subscribed-5")

      Absinthe.Subscription.unsubscribe(PubSub, doc_id)

      refute Absinthe.Subscription.subscribed?(PubSub, :thing, "subscribed-5")
    end

    test "is false when the subscription registry is not running" do
      refute Absinthe.Subscription.subscribed?(NotStartedPubSub, :thing, "anything")
    end
  end

  describe "subscribed_anywhere?/4" do
    test "is true for a local subscriber" do
      subscribe("anywhere-1")

      assert Absinthe.Subscription.subscribed_anywhere?(PubSub, :thing, "anywhere-1")
    end

    test "is false when no node has a subscriber" do
      refute Absinthe.Subscription.subscribed_anywhere?(PubSub, :thing, "anywhere-none")
    end

    test "treats unreachable nodes as having no subscriber" do
      refute Absinthe.Subscription.subscribed_anywhere?(PubSub, :thing, "anywhere-2",
               nodes: [:"nonexistent@127.0.0.1"],
               timeout: 100
             )
    end

    test "still reports a local subscriber when other nodes fail" do
      subscribe("anywhere-3")

      assert Absinthe.Subscription.subscribed_anywhere?(PubSub, :thing, "anywhere-3",
               nodes: [:"nonexistent@127.0.0.1"],
               timeout: 100
             )
    end

    test "is true when a remote node has a subscriber" do
      topic = "anywhere-remote"
      {:ok, peer, node} = start_peer()
      on_exit(fn -> :peer.stop(peer) end)

      remote_subscribe(node, topic)

      assert Absinthe.Subscription.subscribed_anywhere?(PubSub, :thing, topic, nodes: [node])
      refute Absinthe.Subscription.subscribed_anywhere?(PubSub, :thing, "other", nodes: [node])
    end
  end

  # Test modules defined in .exs files are not loadable on the peer, so the peer
  # registers a subscriber under the same registry name and key shape by evaluating code.
  defp remote_subscribe(node, topic) do
    code = """
    registry = Absinthe.Subscription.registry_name(#{inspect(PubSub)})

    spawn(fn ->
      {:ok, _} = Registry.start_link(keys: :duplicate, name: registry)
      {:ok, _} = Registry.register(registry, {:thing, topic}, "doc")
      send(parent, :ready)
      Process.sleep(:infinity)
    end)

    :ok
    """

    {:ok, _result} =
      :erpc.call(node, Code, :eval_string, [code, [parent: self(), topic: topic]])
      |> then(&{:ok, &1})

    assert_receive :ready, 5_000
  end

  defp start_peer do
    unless Node.alive?() do
      # `Node.start/2` does not start epmd the way `--name` at boot does.
      {_, 0} = System.cmd("epmd", ["-daemon"])
      {:ok, _} = Node.start(:"absinthe_test@127.0.0.1", :longnames)
    end

    {:ok, peer, node} =
      :peer.start(%{
        name: :peer.random_name(),
        host: ~c"127.0.0.1",
        longnames: true,
        args: [~c"-setcookie", Atom.to_charlist(Node.get_cookie())]
      })

    :ok = :erpc.call(node, :code, :add_paths, [:code.get_path()])
    {:ok, peer, node}
  end
end
