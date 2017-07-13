defmodule Absinthe.Subscription do
  require Logger
  alias __MODULE__

  defdelegate start_link(pubsub), to: Subscription.Supervisor

  @doc """
  Publish a mutation
  """
  def publish(pubsub, mutation_result, %Absinthe.Resolution{} = info) do
    subscribed_fields = get_subscription_fields(info)
    publish(pubsub, mutation_result, subscribed_fields)
  end
  def publish(pubsub, mutation_result, subscribed_fields) do
    _ = publish_remote(pubsub, mutation_result, subscribed_fields)
    _ = Subscription.Local.publish_mutation(pubsub, mutation_result, subscribed_fields)
    :ok
  end

  defp get_subscription_fields(resolution_info) do
    resolution_info.definition.schema_node.triggers || []
  end

  def subscribe(pubsub, field_key, doc_id, doc) do
    pubsub
    |> registry_name
    |> Registry.register(field_key, {doc_id, doc})
  end

  def unsubscribe(_pubsub, _doc_id) do
    # TODO: do.
    :ok
  end

  @doc false
  def get(pubsub, key) do
    pubsub
    |> registry_name
    |> Registry.lookup(key)
    |> Enum.map(&elem(&1, 1))
    |> Map.new
  end

  @doc false
  def registry_name(pubsub) do
    Module.concat([pubsub, Registry])
  end

  @doc false
  def publish_remote(pubsub, mutation_result, subscribed_fields) do
    {:ok, pool_size} =
      pubsub
      |> registry_name
      |> Registry.meta(:pool_size)

    shard = :erlang.phash2(mutation_result, pool_size)

    proxy_topic = Subscription.Proxy.topic(shard)

    :ok = pubsub.publish_mutation(proxy_topic, mutation_result, subscribed_fields)
  end

  ## Middleware callback
  @doc false
  def call(%{state: :resolved, errors: [], value: value} = res, _) do
    if pubsub = res.context[:pubsub] do
      __MODULE__.publish(pubsub, value, res)
    end
    res
  end
  def call(res, _), do: res

  @doc false
  def add_middleware(middleware) do
    middleware ++ [{__MODULE__, []}]
  end
end
