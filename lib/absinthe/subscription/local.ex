defmodule Absinthe.Subscription.Local do
  @moduledoc false

  require Logger

  # This module handles running and broadcasting documents that are local to this
  # node.

  def publish_mutation(pubsub, mutation_result, subscribed_fields) do
    for {field, key_strategy} <- subscribed_fields,
    {topic, doc} <- get_docs(pubsub, field, mutation_result, key_strategy) do
      doc = put_in(doc.resolution.root_value, mutation_result)

      pipeline = [
        Absinthe.Phase.Document.Execution.Resolution,
        Absinthe.Phase.Document.Result,
      ]

      execution_result = try do
        {:ok, %{result: data}, _} = Absinthe.Pipeline.run(doc, pipeline)

        {:ok, data}
      rescue
        exception ->
          message = Exception.message(exception)
          stacktrace = System.stacktrace |> Exception.format_stacktrace

          Logger.error("""
          #{message}

          #{stacktrace}
          """)
          :error
      end

      with {:ok, data} <- execution_result do
        :ok = pubsub.publish_subscription(topic, data)
      end

    end

    :ok
  end

  defp get_docs(pubsub, field, mutation_result, [topic: topic_fun]) when is_function(topic_fun, 1) do
    do_get_docs(pubsub, field, topic_fun.(mutation_result))
  end
  defp get_docs(pubsub, field, _mutation_result, key) do
    do_get_docs(pubsub, field, to_string(key))
  end

  defp do_get_docs(pubsub, field, keys) do
    keys
    |> List.wrap
    |> Enum.flat_map(&Absinthe.Subscription.get(pubsub, {field, &1}))
  end

end
