defmodule Absinthe.Subscription.Local do
  @moduledoc false

  require Logger

  alias Absinthe.Pipeline.BatchResolver

  # This module handles running and broadcasting documents that are local to this
  # node.

  def publish_mutation(pubsub, mutation_result, subscribed_fields) do
    docs_and_topics = for {field, key_strategy} <- subscribed_fields,
    {topic, doc} <- get_docs(pubsub, field, mutation_result, key_strategy) do
      {topic, put_in(doc.resolution.root_value, mutation_result)}
    end

    if Enum.any?(docs_and_topics) do
      {topics, docs} = Enum.unzip(docs_and_topics)
      docs = BatchResolver.run(docs, [schema: hd(docs).schema, abort_on_error: false])
      pipeline = [
        Absinthe.Phase.Document.Result
      ]
      for {doc, topic} <- Enum.zip(docs, topics), doc != :error do
        try do
          {:ok, %{result: data}, _} = Absinthe.Pipeline.run(doc, pipeline)
          :ok = pubsub.publish_subscription(topic, data)
        rescue
          e ->
            BatchResolver.pipeline_error(e)
        end
      end
    end
  end

  defp get_docs(pubsub, field, mutation_result, [topic: topic_fun]) when is_function(topic_fun, 1) do
    do_get_docs(pubsub, field, topic_fun.(mutation_result))
  end
  defp get_docs(pubsub, field, _mutation_result, key) do
    do_get_docs(pubsub, field, key)
  end

  defp do_get_docs(pubsub, field, keys) do
    keys
    |> List.wrap
    |> Enum.map(&to_string/1)
    |> Enum.flat_map(&Absinthe.Subscription.get(pubsub, {field, &1}))
  end

end
