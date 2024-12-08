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

    result = maybe_add_prime(%{"subscribed" => topic}, prime, blueprint, options)

    {:ok, put_in(blueprint.result, result)}
  end

  def maybe_add_prime(result, nil, _blueprint, _options), do: result

  def maybe_add_prime(result, prime_fun, blueprint, options) when is_function(prime_fun, 1) do
    continuation = %Continuation{
      phase_input: blueprint,
      pipeline: [
        {Phase.Subscription.Prime, [prime_fun: prime_fun, resolution_options: options]},
        {Phase.Document.Execution.Resolution, options},
        Phase.Subscription.GetOrdinal,
        Phase.Document.Result
      ]
    }

    Map.put(result, :continuations, [continuation])
  end

  def maybe_add_prime(_result, prime_fun, _blueprint, _options) do
    raise """
        Invalid prime function. Must be a function of arity 1.

    #{inspect(prime_fun)}
    """
  end
end
