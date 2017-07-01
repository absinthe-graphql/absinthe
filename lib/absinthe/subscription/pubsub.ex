defmodule Absinthe.Subscription.Pubsub do
  @callback subscribe(topic :: binary) :: term

  @callback publish_mutation(proxy_topic :: binary, payload :: map) :: term

  @callback publish_subscription(topic :: binary, data :: map) :: term

end
