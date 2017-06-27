defmodule Absinthe.Subscription.Local do
  @moduledoc false

  require Logger

  # This module handles running and broadcasting documents that are local to this
  # node.

  def publish_mutation(pubsub, subscribed_fields, mutation_result) do

    root_value = Map.new(subscribed_fields, fn {field, _} ->
      {field, mutation_result}
    end)

    for {field, key_strategy} <- subscribed_fields,
    {topic, doc} <- get_docs(pubsub, field, mutation_result, key_strategy) |> IO.inspect do

      root_value = Map.merge(doc.resolution.root_value || %{}, root_value)
      doc = put_in(doc.resolution.root_value, root_value)

      pipeline = [
        Absinthe.Phase.Document.Execution.Resolution,
        Absinthe.Phase.Document.Result,
      ]

      try do
        {:ok, %{result: data}, _} = Absinthe.Pipeline.run(doc, pipeline)

        data |> IO.inspect

        # TODO: direct broadcast for local nodes only when we handle distribution
        # MyApp.Pub
        # |> Phoenix.PubSub.node_name()
        # |> Phoenix.PubSub.direct_broadcast(MyApp.Pub, topic, %Phoenix.Socket.Broadcast{topic, event, payload})

        :ok = pubsub.broadcast(topic, "subscription:data", %{subscription_id: topic, result: data})
      rescue
        x ->
          # not doing the right thing here yet
          Logger.info(inspect(x))
      end

    end

    :ok
  end

  defp get_docs(pubsub, field, mutation_result, [topic: topic_fun]) do
    key = {field, topic_fun.(mutation_result)}
    Absinthe.Subscription.get(pubsub, key)
  end

end
