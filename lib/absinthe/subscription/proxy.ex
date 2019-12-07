defmodule Absinthe.Subscription.Proxy do
  @moduledoc false

  use GenServer

  defstruct [
    :pubsub,
    :node,
    :task_super
  ]

  def child_spec([_, _, shard] = args) do
    %{
      id: {__MODULE__, shard},
      start: {__MODULE__, :start_link, [args]}
    }
  end

  alias Absinthe.Subscription

  @gc_interval 5_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def topic(shard), do: "__absinthe__:proxy:#{shard}"

  def init([task_super, pubsub, shard]) do
    node_name = pubsub.node_name()
    :ok = pubsub.subscribe(topic(shard))
    Process.send_after(self(), :gc, @gc_interval)
    {:ok, %__MODULE__{pubsub: pubsub, node: node_name, task_super: task_super}}
  end

  def handle_info(:gc, state) do
    :erlang.garbage_collect()
    Process.send_after(self(), :gc, @gc_interval)
    {:noreply, state}
  end

  def handle_info(payload, state) do
    # There's no meaningful form of backpressure to have here, and we can't
    # bottleneck execution inside each proxy process

    unless payload.node == state.pubsub.node_name() do
      Task.Supervisor.start_child(state.task_super, Subscription.Local, :publish_mutation, [
        state.pubsub,
        payload.mutation_result,
        payload.subscribed_fields
      ])
    end

    {:noreply, state}
  end
end
