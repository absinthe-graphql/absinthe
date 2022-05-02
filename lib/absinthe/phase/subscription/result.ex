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
        do_prime(prime_fun, result, blueprint, options)

      val ->
        raise """
        Invalid prime function. Must be a function of arity 1.

        #{inspect(val)}
        """
    end
  end

  def do_prime(prime_fun, base_result, blueprint, options) do
    {:ok, prime_results} = prime_fun.(blueprint.execution)

    result =
      if prime_results != [] do
        continuations =
          Enum.map(prime_results, fn cr ->
            %Continuation{
              phase_input: blueprint,
              pipeline: [
                {Phase.Subscription.Prime, [prime_result: cr]},
                {Phase.Document.Execution.Resolution, options},
                Phase.Subscription.GetOrdinal,
                Phase.Document.Result
              ]
            }
          end)

        Map.put(base_result, :continuation, continuations)
      else
        base_result
      end

    {:ok, put_in(blueprint.result, result)}
  end
end
