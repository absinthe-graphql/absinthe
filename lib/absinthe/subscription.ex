defmodule Absinthe.Subscription do
  @moduledoc """
  Real time updates via GraphQL

  For a how to guide on getting started with Absinthe.Subscriptions in your phoenix
  project see the Absinthe.Phoenix package.

  Define in your schema via `Absinthe.Schema.subscription/2`
  """

  require Logger
  alias __MODULE__

  @doc """
  Add Absinthe.Subscription to your process tree.
  """
  defdelegate start_link(pubsub), to: Subscription.Supervisor

  @type subscription_field_spec :: {atom, term | ((term) -> term)}

  @doc """
  Publish a mutation
  """
  @spec publish(Absinthe.Subscription.Pubsub.t, term, Absinthe.Resolution.t | [subscription_field_spec]) :: :ok
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

  @doc false
  def subscribe(pubsub, field_key, doc_id, doc) do
    registry = pubsub |> registry_name

    {:ok, _} = Registry.register(registry, field_key, {doc_id, doc})
    {:ok, _} = Registry.register(registry, doc_id, field_key)
  end

  @doc """
  Unsubscribe the current process from a given doc id
  """
  def unsubscribe(pubsub, doc_id) do
    registry = pubsub |> registry_name

    for {_, field_key} <- Registry.lookup(registry, doc_id) do
      do_unsubscribe(registry, field_key, doc_id)
    end
    Registry.unregister(registry, doc_id)
    :ok
  end

  # TODO: Replace with Registry.match_delete when it exists
  def do_unsubscribe(registry, key, doc_id) do
    self = self()
    spec = {key, {self, {doc_id, :_}}}

    {kind, partitions, key_ets, pid_ets, listeners} = info!(registry)
    {key_partition, pid_partition} = partitions(kind, key, self, partitions)
    key_ets = key_ets || key_ets!(registry, key_partition)
    {pid_server, pid_ets} = pid_ets || pid_ets!(registry, pid_partition)

    # Remove first from the key_ets because in case of crashes
    # the pid_ets will still be able to clean up. The last step is
    # to clean if we have no more entries.
    true = :ets.match_delete(key_ets, spec)
    true = :ets.delete_object(pid_ets, {self, key, key_ets})

    unlink_if_unregistered(pid_server, pid_ets, self)

    for listener <- listeners do
      Kernel.send(listener, {:unregister, registry, key, self})
    end
    :ok
  end

  @all_info -1
  defp info!(registry) do
    try do
      :ets.lookup_element(registry, @all_info, 2)
    catch
      :error, :badarg ->
        raise ArgumentError, "unknown registry: #{inspect registry}"
    end
  end

  defp unlink_if_unregistered(pid_server, pid_ets, self) do
    unless :ets.member(pid_ets, self) do
      Process.unlink(pid_server)
    end
  end

  defp partitions(:unique, key, pid, partitions) do
    {hash(key, partitions), hash(pid, partitions)}
  end
  defp partitions(:duplicate, _key, pid, partitions) do
    partition = hash(pid, partitions)
    {partition, partition}
  end

  defp key_ets!(registry, partition) do
    :ets.lookup_element(registry, partition, 2)
  end

  defp pid_ets!(registry, partition) do
    :ets.lookup_element(registry, partition, 3)
  end

  # @compile {:inline, hash: 2}

  defp hash(term, limit) do
    :erlang.phash2(term, limit)
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
