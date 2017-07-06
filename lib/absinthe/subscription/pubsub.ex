defmodule Absinthe.Subscription.Pubsub do
  @callback subscribe(topic :: binary) :: term

  @callback publish_mutation(proxy_topic :: binary, subscribed_fields :: list, mutation_result :: term) :: term

  @callback publish_subscription(topic :: binary, data :: map) :: term

end
