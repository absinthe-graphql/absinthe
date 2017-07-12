defmodule Absinthe.Phase.SubscribeSelf do
  use Absinthe.Phase

  @moduledoc false

  # If you're looking for the core of subscriptions this is not really it.
  # This phase exists to handle when someone does `Absinthe.run` with a subscription
  # it subscribes the local process.

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t) :: {:ok, Blueprint.t}
  def run(blueprint, _ \\ []) do
    with %{type: :subscription} <- Blueprint.current_operation(blueprint) do
      raise "Subscriptions are not yet supported via Absinthe.run"
    end

    {:ok, blueprint}
  end

end
