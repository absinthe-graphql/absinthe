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

    run_docset_fn =
      if function_exported?(pubsub, :run_docset, 3), do: &pubsub.run_docset/3, else: &run_docset/3

    run_docset_fn.(pubsub, docs_and_topics, mutation_result)

    :ok
  end

  alias Absinthe.{Phase, Pipeline}

  defp run_docset(pubsub, docs_and_topics, mutation_result) do
    for {topic, key_strategy, doc} <- docs_and_topics do
      try do
        pipeline = pipeline(doc, mutation_result)

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

  def pipeline(doc, mutation_result) do
    pipeline =
      doc.initial_phases
      |> Pipeline.replace(
        Phase.Telemetry,
        {Phase.Telemetry, event: [:subscription, :publish, :start]}
      )
      |> Pipeline.without(Phase.Subscription.SubscribeSelf)
      |> Pipeline.insert_before(
        Phase.Document.Execution.Resolution,
        [
          {Phase.Document.OverrideRoot, root_value: mutation_result},
          Phase.Subscription.GetOrdinal
        ]
      )
      |> Pipeline.upto(Phase.Document.Execution.Resolution)

    pipeline = [
      pipeline,
      [
        result_phase(doc),
        {Absinthe.Phase.Telemetry, event: [:subscription, :publish, :stop]}
      ]
    ]

    pipeline
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

  defp result_phase(doc) do
    # use the configured result phase from the initial pipeline
    # this will allow the result of the subscription data to match
    # the output of query/mutation. An example of result phase is
    # Absinthe.Phoenix.Controller.Result where the output will have
    # atom keys and allow struct to be returned

    doc.initial_phases
    |> Pipeline.from(Phase.Blueprint)
    |> case do
      [{Phase.Blueprint, opts} | _] ->
        Keyword.get(opts, :result_phase, Phase.Document.Result)

      _ ->
        Phase.Document.Result
    end
  end
end
