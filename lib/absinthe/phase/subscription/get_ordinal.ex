defmodule Absinthe.Phase.Subscription.GetOrdinal do
  use Absinthe.Phase

  alias Absinthe.Phase.Subscription.SubscribeSelf

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t()) :: {:ok, Blueprint.t()}
  def run(blueprint, _options \\ []) do
    with %{type: :subscription, selections: [field]} <- Blueprint.current_operation(blueprint),
         {:ok, config} = SubscribeSelf.get_config(field, blueprint.execution.context, blueprint),
         ordinal_fun when is_function(ordinal_fun, 1) <- config[:ordinal] do
      result = ordinal_fun.(blueprint.execution.root_value)
      {:ok, %{blueprint | result: Map.put(blueprint.result, :ordinal, result)}}
    else
      f when is_function(f) ->
        IO.write(
          :stderr,
          "Ordinal function must be 1-arity"
        )

        {:ok, blueprint}

      _ ->
        {:ok, blueprint}
    end
  end
end
