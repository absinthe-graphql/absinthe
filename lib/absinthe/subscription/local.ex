defmodule Absinthe.Subscription.Local do
  @moduledoc """
  This module handles broadcasting documents that are local to this node
  """

  @default_opts [
    docset_runner: Absinthe.Subscription.DocSetRunner.Simple
  ]
  @doc """
  Publish a mutation to the local node only.

  See also `Absinthe.Subscription.publish/3`
  """
  @spec publish_mutation(
          Absinthe.Subscription.Pubsub.t(),
          term,
          [Absinthe.Subscription.subscription_field_spec()]
        ) :: :ok
  def publish_mutation(
        pubsub,
        mutation_result,
        subscribed_fields,
        opts \\ @default_opts
      ) do
    doc_topics =
      for {field, key_strategy} <- subscribed_fields,
          {topic, doc} <- get_docs(pubsub, field, mutation_result, key_strategy) do
        %Absinthe.Subscription.Document{
          topic: topic,
          field: field,
          key_strategy: key_strategy,
          initial_phases: doc.initial_phases,
          source: doc.source
        }
      end

    opts[:docset_runner].run(pubsub, doc_topics, mutation_result)

    :ok
  end

  defp get_docs(pubsub, field, mutation_result, topic: topic_fun)
       when is_function(topic_fun, 1) do
    do_get_docs(pubsub, field, topic_fun.(mutation_result))
  end

  defp get_docs(pubsub, field, _mutation_result, key) do
    do_get_docs(pubsub, field, key)
  end

  defp do_get_docs(pubsub, field, keys) do
    keys
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.flat_map(&Absinthe.Subscription.get(pubsub, {field, &1}))
  end
end
