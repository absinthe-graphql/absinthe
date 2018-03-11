defmodule Absinthe.Phase.Subscription.Result do
  @moduledoc false

  # This runs instead of resolution and the normal result phase after a successful
  # subscription

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t()) :: {:ok, Blueprint.t()}
  def run(blueprint, topic: topic) do
    result = %{"subscribed" => topic}
    {:ok, put_in(blueprint.result, result)}
  end
end
