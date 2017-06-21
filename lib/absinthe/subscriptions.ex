defmodule Absinthe.Subscriptions do
  require Logger

  @doc "Publish a mutation"
  def publish_from_mutation(endpoint, field_res, mutation_result) do
    subscribed_fields = get_subscription_fields(field_res)

    root_value = Map.new(subscribed_fields, fn {field, _} ->
      {field, mutation_result}
    end)

    for {field, key_strategy} <- subscribed_fields,
    {topic, doc} <- get_docs(endpoint, field, mutation_result, key_strategy) do

      root_value = Map.merge(doc.resolution.root_value || %{}, root_value)
      doc = put_in(doc.resolution.root_value, root_value)

      pipeline = [
        Absinthe.Phase.Document.Execution.Resolution,
        Absinthe.Phase.Document.Result,
      ]

      try do
        {:ok, %{result: data}, _} = Absinthe.Pipeline.run(doc, pipeline)

        # TODO: direct broadcast for local nodes only when we handle distribution
        # MyApp.Pub
        # |> Phoenix.PubSub.node_name()
        # |> Phoenix.PubSub.direct_broadcast(MyApp.Pub, topic, %Phoenix.Socket.Broadcast{topic, event, payload})

        endpoint.broadcast!(topic, "subscription:data", %{subscription_id: topic, result: data})
      rescue
        x ->
          Logger.error(inspect(x))
      end

    end
  end

  defp get_subscription_fields(field_res) do
    field_res.definition.schema_node.triggers || []
  end

  defp get_docs(endpoint, field, mutation_result, [topic: topic_fun]) do
    key = {field, topic_fun.(mutation_result)}
    Absinthe.Subscriptions.Manager.subscriptions(endpoint, key)
  end

  @doc false
  def call(%{state: :resolved, errors: [], value: value} = res, _) do
    if pubsub = res.context[:__absinthe__][:pubsub] do
      Absinthe.Subscriptions.publish_from_mutation(pubsub, res, value)
    end
    res
  end
  def call(res, _), do: res

  @doc false
  def add_middleware(middleware) do
    middleware ++ [{__MODULE__, []}]
  end
end
