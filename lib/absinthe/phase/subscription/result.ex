defmodule Absinthe.Phase.Subscription.Result do
  @moduledoc false

  # This runs instead of resolution and the normal result phase after a successful
  # subscription

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Continuation

  @spec run(any, Keyword.t()) :: {:ok, Blueprint.t()}
  def run(blueprint, options) do
    topic = Keyword.get(options, :topic)
    prime = Keyword.get(options, :prime)
    result = %{"subscribed" => topic}
    case prime do
      nil ->
        {:ok, put_in(blueprint.result, result)}

      prime_fun when is_function(prime_fun, 0) ->
        {:ok, prime_results} = prime_fun.()

        result =
          if prime_results != [] do
            continuations =
              Enum.map(prime_results, fn cr ->
                %Continuation{
                  phase_input: blueprint,
                  pipeline: [
                    {Absinthe.Phase.Subscription.Prime, [prime_result: cr]},
                    {Absinthe.Phase.Document.Execution.Resolution, options},
                    Absinthe.Phase.Document.Result
                  ]
                }
              end)

            Map.put(result, :continuation, continuations)
          else
            result
          end

        {:ok, put_in(blueprint.result, result)}

      val ->
        raise """
        Invalid prime function. Must be a function of arity 0.

        #{inspect(val)}
        """
    end
  end
end
