defmodule Absinthe.Subscription.DocSetRunner do
  @moduledoc """
  Behaviour on how to run a set of documents
  for a subscription.
  """

  @callback run(
              pubsub :: Absinthe.Subscription.Pubsub.t(),
              docs_and_topics :: [Absinthe.Subscription.Document.t()],
              mutation_result :: term
            ) :: term
end
