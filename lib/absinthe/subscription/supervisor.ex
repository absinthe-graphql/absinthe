defmodule Absinthe.Subscription.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    pubsub =
      case Keyword.fetch!(opts, :pubsub) do
        [module] when is_atom(module) ->
          module

        module ->
          module
      end

    pool_size = Keyword.get(opts, :pool_size, System.schedulers_online() * 2)
    compress_registry? = Keyword.get(opts, :compress_registry?, true)

    Supervisor.start_link(__MODULE__, {pubsub, pool_size, compress_registry?})
  end

  def init({pubsub, pool_size, compress_registry?}) do
    registry_name = Absinthe.Subscription.registry_name(pubsub)
    meta = [pool_size: pool_size]

    children = [
      {Registry,
       [
         keys: :duplicate,
         name: registry_name,
         partitions: System.schedulers_online(),
         meta: meta,
         compressed: compress_registry?
       ]},
      {Absinthe.Subscription.ProxySupervisor, [pubsub, registry_name, pool_size]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
