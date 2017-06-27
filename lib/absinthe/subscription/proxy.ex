defmodule Absinthe.Subscription.Proxy do
  use GenServer

  def start_link(pubsub, shard) do
    GenServer.start_link(__MODULE__, {pubsub, shard})
  end

  def topic(shard), do: "__absinthe__:proxy:#{shard}"

  def init({pubsub, shard}) do
    :ok = pubsub.subscribe(topic(shard))
    {:ok, [pubsub]}
  end

  def handle_info(%{payload: %{node: src_node}}, state) when src_node == node() do
    {:noreply, state}
  end
  def handle_info(%{payload: payload}, state) do
    payload |> IO.inspect
    {:noreply, state}
  end

  # def handle_info for messages
end
