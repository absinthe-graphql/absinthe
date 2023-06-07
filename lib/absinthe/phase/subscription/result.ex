defmodule Absinthe.Phase.Subscription.Result do
  @moduledoc false

  # This runs instead of resolution and the normal result phase after a successful
  # subscription

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Continuation
  alias Absinthe.Phase

  @spec run(any, Keyword.t()) :: {:ok, Blueprint.t()}
  def run(blueprint, options) do
    topic = Keyword.fetch!(options, :topic)
    prime = Keyword.get(options, :prime)
    result = %{"subscribed" => topic}

    case prime do
      nil ->
        {:ok, put_in(blueprint.result, result)}

      prime_fun when is_function(prime_fun, 1) ->
        stash_prime(prime_fun, result, blueprint, options)

      val ->
        raise """
        Invalid prime function. Must be a function of arity 1.

        #{inspect(val)}
        """
    end
  end

  def stash_prime(prime_fun, base_result, blueprint, options) do
    continuation = %Continuation{
      phase_input: blueprint,
      pipeline: [
        {Phase.Subscription.Prime, [prime_fun: prime_fun, resolution_options: options]},
        {Phase.Document.Execution.Resolution, options},
        Phase.Subscription.GetOrdinal,
        Phase.Document.Result
      ]
    }

    result = Map.put(base_result, :continuations, [continuation])

    {:ok, put_in(blueprint.result, result)}
  end
end
