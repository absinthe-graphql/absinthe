defmodule Absinthe.Subscription.Proxy do
  @moduledoc false

  use GenServer

  defstruct [
    :pubsub
  ]

  alias Absinthe.Subscription

  def start_link(pubsub, shard) do
    GenServer.start_link(__MODULE__, {pubsub, shard})
  end

  def topic(shard), do: "__absinthe__:proxy:#{shard}"

  def init({pubsub, shard}) do
    :ok = pubsub.subscribe(topic(shard))
    {:ok, %__MODULE__{pubsub: pubsub}}
  end

  def handle_info(%{node: src_node}, state) when src_node == node() do
    {:noreply, state}
  end
  def handle_info(payload, state) do
    Subscription.Local.publish_mutation(state.pubsub, payload.mutation_result, payload.subscribed_fields)
    {:noreply, state}
  end
end
