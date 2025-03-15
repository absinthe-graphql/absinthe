defmodule Absinthe.Subscription do
  @moduledoc """
  Real time updates via GraphQL

  For a how to guide on getting started with Absinthe.Subscriptions in your phoenix
  project see the `Absinthe.Phoenix` package.

  Define in your schema via `Absinthe.Schema.subscription/2`

  ## Basic Usage

  ## Performance Characteristics

  There are a couple of limitations to the beta release of subscriptions that
  are worth keeping in mind if you want to use this in production:

  By design, all subscription docs triggered by a mutation are run inside the
  mutation process as a form of back pressure.

  At the moment however database batching does not happen across the set of
  subscription docs. Thus if you have a lot of subscription docs and they each
  do a lot of extra DB lookups you're going to delay incoming mutation responses
  by however long it takes to do all that work.

  Before the final version of 1.4.0 we want

  - Batching across subscriptions
  - More user control over back pressure / async balance.
  """

  alias __MODULE__

  alias Absinthe.Subscription.PipelineSerializer

  @doc """
  Add Absinthe.Subscription to your process tree.
  """
  @spec start_link(atom() | [opt()]) :: Supervisor.on_start()
  defdelegate start_link(opts_or_pubsub), to: Subscription.Supervisor

  @type opt() ::
          {:pubsub, atom()} | {:compress_registry?, boolean()} | {:pool_size, pos_integer()}

  @doc """
  Build a child specification for subscriptions.

  In order to use subscriptions in your application, you must add
  `Absinthe.Subscription` to your supervision tree after your endpoint.

  See `guides/subscriptions.md` for more information on how to get up and
  running with subscriptions.

  ## Options

  * `:pubsub` - (Required) The `Phoenix.Pubsub` that should be used to publish
    subscriptions. Typically this will be your `Phoenix.Endpoint`.
  * `:compress_registry?` - (Optional - default `true`) A boolean controlling
    whether the Registry used to keep track of subscriptions will should be
    compressed or not.
  * `:pool_size` - (Optional - default `System.schedulers() * 2`) An integer
    specifying the number of `Absinthe.Subscription.Proxy` processes to start.
    You may want to specify a fixed `:pool_size` if your deployment environment
    does not guarantee an equal number of CPU cores to be available on all
    application nodes. In such case, using the defaults may lead to missing
    messages. This situation often happens on cloud-based deployment environments.
  """
  @spec child_spec(atom() | [opt()]) :: Supervisor.child_spec()
  def child_spec(pubsub) when is_atom(pubsub) do
    # child_spec/1 used to take a single argument - the pub-sub - so in order
    # to maintain compatibility for existing users of the library we still
    # accept this argument and transform it into a keyword list.
    child_spec(pubsub: pubsub)
  end

  def child_spec(opts) when is_list(opts) do
    %{
      id: __MODULE__,
      start: {Subscription.Supervisor, :start_link, [opts]},
      type: :supervisor
    }
  end

  @type subscription_field_spec :: {atom, term | (term -> term)}

  @doc """
  Publish a mutation

  This function is generally used when trying to publish to one or more subscription
  fields "out of band" from any particular mutation.

  ## Examples

  Note: As with all subscription examples if you're using Absinthe.Phoenix `pubsub`
  will be `MyAppWeb.Endpoint`.

  ```
  Absinthe.Subscription.publish(pubsub, user, [new_users: user.account_id])
  ```
  ```
  # publish to two subscription fields
  Absinthe.Subscription.publish(pubsub, user, [
    new_users: user.account_id,
    other_user_subscription_field: user.id,
  ])
  ```
  """
  @spec publish(
          Absinthe.Subscription.Pubsub.t(),
          term,
          Absinthe.Resolution.t() | [subscription_field_spec]
        ) :: :ok
  def publish(_pubsub, _mutation_result, []), do: :ok

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
    mutation_field = resolution_info.definition.schema_node
    schema = resolution_info.schema
    subscription = Absinthe.Schema.lookup_type(schema, :subscription) || %{fields: []}

    subscription_fields = fetch_fields(subscription.fields, mutation_field.triggers)

    for {sub_field_id, sub_field} <- subscription_fields do
      triggers = Absinthe.Type.function(sub_field, :triggers)
      config = Map.fetch!(triggers, mutation_field.identifier)
      {sub_field_id, config}
    end
  end

  # TODO: normalize the `.fields` type.
  defp fetch_fields(fields, triggers) when is_map(fields) do
    Map.take(fields, triggers)
  end

  defp fetch_fields(_, _), do: []

  @doc false
  def subscribe(pubsub, field_keys, doc_id, doc) do
    field_keys = List.wrap(field_keys)

    registry = pubsub |> registry_name

    doc_value = %{
      initial_phases: PipelineSerializer.pack(doc.initial_phases),
      source: doc.source
    }

    pdict_add_fields(doc_id, field_keys)

    for field_key <- field_keys do
      {:ok, _} = Registry.register(registry, field_key, doc_id)
    end

    {:ok, _} = Registry.register(registry, doc_id, doc_value)
  end

  defp pdict_fields(doc_id) do
    Process.get({__MODULE__, doc_id}, [])
  end

  defp pdict_add_fields(doc_id, field_keys) do
    Process.put({__MODULE__, doc_id}, field_keys ++ pdict_fields(doc_id))
  end

  defp pdict_delete_fields(doc_id) do
    Process.delete({__MODULE__, doc_id})
  end

  @doc false
  def unsubscribe(pubsub, doc_id) do
    registry = pubsub |> registry_name

    for field_key <- pdict_fields(doc_id) do
      Registry.unregister_match(registry, field_key, doc_id)
    end

    Registry.unregister(registry, doc_id)

    pdict_delete_fields(doc_id)
    :ok
  end

  @doc false
  def get(pubsub, key) do
    name = registry_name(pubsub)

    name
    |> Registry.lookup(key)
    |> MapSet.new(fn {_pid, doc_id} -> doc_id end)
    |> Enum.reduce([], fn doc_id, acc ->
      case Registry.lookup(name, doc_id) do
        [] ->
          acc

        [{_pid, doc} | _rest] ->
          doc = Map.update!(doc, :initial_phases, &PipelineSerializer.unpack/1)
          [{doc_id, doc} | acc]
      end
    end)
    |> Map.new()
  end

  @doc false
  def registry_name(pubsub) do
    Module.concat([pubsub, :Registry])
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
    with {:ok, pubsub} <- extract_pubsub(res.context) do
      __MODULE__.publish(pubsub, value, res)
    end

    res
  end

  def call(res, _), do: res

  @doc false
  def extract_pubsub(context) do
    with {:ok, pubsub} <- Map.fetch(context, :pubsub),
         pid when is_pid(pid) <- Process.whereis(registry_name(pubsub)) do
      {:ok, pubsub}
    else
      _ -> :error
    end
  end

  @doc false
  def add_middleware(middleware) do
    middleware ++ [{__MODULE__, []}]
  end
end
