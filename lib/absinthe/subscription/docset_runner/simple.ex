defmodule Absinthe.Subscription.DocSetRunner.Simple do
  @moduledoc """
  Default runner for subscription docs

  This runner will iterate over the subscription docs and run them sequentially.
  It is run in inside of a mutation, so it will block the mutation response
  until all subscription docs have been run, giving a form of back pressure.

  Furthermore, no batching takes place between the documents. If document A
  queries the database for some data, and document B queries the database for
  the same data, then the database will be queried twice.
  """
  @behaviour Absinthe.Subscription.DocSetRunner
  require Logger

  alias Absinthe.Pipeline.BatchResolver
  alias Absinthe.Pipeline
  alias Absinthe.Subscription

  def run(pubsub, subscription_docs, mutation_result) do
    for subscription_doc <- subscription_docs do
      try do
        pipeline = Subscription.Document.pipeline(subscription_doc, root_value: mutation_result)
        {:ok, %{result: data}, _} = Pipeline.run(subscription_doc.source, pipeline)

        Logger.debug("""
        Absinthe Subscription Publication
        Field Topic: #{inspect(subscription_doc.key_strategy)}
        Subscription id: #{inspect(subscription_doc.topic)}
        Data: #{inspect(data)}
        """)

        :ok = pubsub.publish_subscription(subscription_doc.topic, data)
      rescue
        e ->
          BatchResolver.pipeline_error(e, __STACKTRACE__)
      end
    end
  end
end
