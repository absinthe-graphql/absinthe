defmodule Absinthe.Phase.Subscription.GetOrdinal do
  use Absinthe.Phase

  alias Absinthe.Phase.Subscription.SubscribeSelf

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t()) :: {:ok, Blueprint.t()}
  def run(blueprint, _options \\ []) do
    op = Blueprint.current_operation(blueprint)

    if op.type == :subscription do
      {:ok,
       %{blueprint | result: Map.put(blueprint.result, :ordinal, get_ordinal(op, blueprint))}}
    else
      {:ok, blueprint}
    end
  end

  defp get_ordinal(op, blueprint) do
    %{selections: [field]} = op
    {:ok, config} = SubscribeSelf.get_config(field, blueprint.execution.context, blueprint)

    case config[:ordinal] do
      nil ->
        nil

      fun when is_function(fun, 1) ->
        fun.(blueprint.execution.root_value)

      _fun ->
        IO.write(
          :stderr,
          "Ordinal function must be 1-arity"
        )

        nil
    end
  end
end
