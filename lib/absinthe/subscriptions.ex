defmodule Absinthe.Subscriptions do
  def publish_from_mutation(endpoint, field_res, mutation_result) do
    subscribed_fields = get_subscription_fields(field_res)

    root_value = Map.new(subscribed_fields, fn {field, _} ->
      {field, mutation_result}
    end)

    for {field, key_strategy} <- subscribed_fields,
    {topic, doc} <- get_docs(endpoint, field, mutation_result, key_strategy) do

      pipeline = [
        {Absinthe.Phase.Document.Execution.Resolution, root_value: root_value},
        Absinthe.Phase.Document.Result,
      ]

      {:ok, data, _} = Absinthe.Pipeline.run(doc, pipeline)

      # TODO: direct broadcast for local nodes only when we handle distribution
      # MyApp.Pub
      # |> Phoenix.PubSub.node_name()
      # |> Phoenix.PubSub.direct_broadcast(MyApp.Pub, topic, %Phoenix.Socket.Broadcast{topic, event, payload})

      endpoint.broadcast!(topic, "subscription:data", data)
    end
  end

  defp get_subscription_fields(field_res) do
    field_res.definition.schema_node.triggers
  end

  defp get_docs(endpoint, field, mutation_result, [topic: topic_fun]) do
    key = {field, topic_fun.(mutation_result)}
    Absinthe.Subscriptions.Manager.subscriptions(endpoint, key)
  end
end
