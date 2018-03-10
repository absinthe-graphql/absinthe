defmodule Absinthe.Subscription.Pubsub do
  @moduledoc """
  Pubsub behaviour expected by Absinthe to power subscriptions

  Absinthe does not require any particular backend to support subscriptions, but
  it does require that any candidate pubsub implement a couple of functions.

  In addition to the type signatures there are a couple of recommended implementation
  suggestions associated with each function, be sure to read the docs for each.

  Note: with the Absinthe.Phoenix package a Phoenix endpoint can be used for pubsub.
  """

  @type t :: module()

  @doc """
  Subscribe the current process via a given topic
  """
  @callback subscribe(topic :: binary) :: term

  @doc """

  """
  @callback publish_mutation(
              proxy_topic :: binary,
              mutation_result :: term,
              subscribed_fields :: list
            ) :: term

  @doc """
  Publish the results of a particular subscription document. This should be a local
  node broadcast. If you can
  """
  @callback publish_subscription(topic :: binary, data :: map) :: term
end
