defmodule Absinthe.Subscription.Local do
  @moduledoc """
  This module handles broadcasting documents that are local to this node
  """

  require Logger

  alias Absinthe.Pipeline.BatchResolver

  # This module handles running and broadcasting documents that are local to this
  # node.

  @doc """
  Publish a mutation to the local node only.

  See also `Absinthe.Subscription.publish/3`
  """
  @spec publish_mutation(
          Absinthe.Subscription.Pubsub.t(),
          term,
          [Absinthe.Subscription.subscription_field_spec()]
        ) :: :ok
  def publish_mutation(pubsub, mutation_result, subscribed_fields) do
    docs_and_topics =
      for {field, key_strategy} <- subscribed_fields,
          {topic, doc} <- get_docs(pubsub, field, mutation_result, key_strategy) do
        {topic, key_strategy, doc}
      end
      |> Enum.dedup_by(fn {topic, key_strategy, _} ->
        "#{topic}_#{:erlang.phash2(key_strategy)}"
      end)

    run_docset(pubsub, docs_and_topics, mutation_result)

    :ok
  end

  alias Absinthe.{Phase, Pipeline}

  defp run_docset(pubsub, docs_and_topics, mutation_result) do
    for {topic, key_strategy, doc} <- docs_and_topics do
      try do
        pipeline =
          doc.initial_phases
          |> Pipeline.replace(
            Phase.Telemetry,
            {Phase.Telemetry, event: [:subscription, :publish, :start]}
          )
          |> Pipeline.without(Phase.Subscription.SubscribeSelf)
          |> Pipeline.insert_before(
            Phase.Document.Execution.Resolution,
            {Phase.Document.OverrideRoot, root_value: mutation_result}
          )
          |> Pipeline.upto(Phase.Document.Execution.Resolution)

        pipeline = [
          pipeline,
          [
            Absinthe.Phase.Document.Result,
            {Absinthe.Phase.Telemetry, event: [:subscription, :publish, :stop]}
          ]
        ]

        {:ok, %{result: data}, _} = Absinthe.Pipeline.run(doc.source, pipeline)

        Logger.debug("""
        Absinthe Subscription Publication
        Field Topic: #{inspect(key_strategy)}
        Subscription id: #{inspect(topic)}
        Data: #{inspect(data)}
        """)

        :ok = pubsub.publish_subscription(topic, data)
      rescue
        e ->
          BatchResolver.pipeline_error(e, __STACKTRACE__)
      end
    end
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
