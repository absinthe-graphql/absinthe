defmodule Absinthe.Subscription.Supervisor do
  @moduledoc false

  use Supervisor

  @spec start_link(atom() | [Absinthe.Subscription.opt()]) :: Supervisor.on_start()
  def start_link(pubsub) when is_atom(pubsub) do
    # start_link/1 used to take a single argument - the pub-sub - so in order
    # to maintain compatibility for existing users of the library we still
    # accept this argument and transform it into a keyword list.
    start_link(pubsub: pubsub)
  end

  def start_link(opts) when is_list(opts) do
    pubsub =
      case Keyword.fetch!(opts, :pubsub) do
        [module] when is_atom(module) ->
          module

        module ->
          module
      end

    pool_size = Keyword.get(opts, :pool_size, System.schedulers_online() * 2)
    compress_registry? = Keyword.get(opts, :compress_registry?, true)

    # Absinthe.Subscription.Proxy listens for subscription messages
    # from other nodes and then runs Subscription.Local.publish_mutation to process
    # the mutation on the local node. By default it runs in a task superivsor so that
    # requests are handled concurrently. However, this may not work for some
    # systems. Setting `async` to false makes it so that the requests are processed one at a time.
    async? = Keyword.get(opts, :async, true)

    # Determines how keys in the registry are partitioned.
    # Absinthe expects duplicate keys and by default used the :duplicate option.
    # In Elixir 1.19 there are more options to determine how the duplicate keys
    # are partitioned. {:duplicate, :pid} which is the same as :duplicate and
    # {:duplicate, :keys} which partitioned by key.
    registry_partition_strategy = Keyword.get(opts, :registry_partition_strategy, :pid)

    Supervisor.start_link(
      __MODULE__,
      {pubsub, pool_size, compress_registry?, async?, registry_partition_strategy}
    )
  end

  def init({pubsub, pool_size, compress_registry?, async?, registry_partition_strategy}) do
    registry_name = Absinthe.Subscription.registry_name(pubsub)
    meta = [pool_size: pool_size]

    keys =
      case registry_partition_strategy do
        # to support Elixir versions before 1.19
        :pid -> :duplicate
        _ -> {:duplicate, :key}
      end

    children = [
      {Registry,
       [
         keys: keys,
         name: registry_name,
         partitions: System.schedulers_online(),
         meta: meta,
         compressed: compress_registry?
       ]},
      {Absinthe.Subscription.ProxySupervisor, [pubsub, registry_name, pool_size, async?]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
