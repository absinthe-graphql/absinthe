defmodule Absinthe.Subscription.Supervisor do
  @moduledoc false

  use Supervisor

  alias Absinthe.Subscription.Registry

  def start_link(pubsub, pool_size \\ System.schedulers_online() * 2) do
    Supervisor.start_link(__MODULE__, {pubsub, pool_size})
  end

  def init({pubsub, pool_size}) do
    registry_name = Absinthe.Subscription.registry_name(pubsub)
    meta = [pool_size: pool_size]

    children = [
      supervisor(Registry, [
        :duplicate,
        registry_name,
        [partitions: System.schedulers_online(), meta: meta]
      ]),
      supervisor(Absinthe.Subscription.ProxySupervisor, [pubsub, registry_name, pool_size])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
