defmodule Absinthe.Phase.Subscription.GetOrdinal do
  use Absinthe.Phase

  alias Absinthe.Phase.Subscription.SubscribeSelf

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t()) :: {:ok, Blueprint.t()}
  def run(blueprint, _options \\ []) do
    with %{type: :subscription, selections: [field]} <- Blueprint.current_operation(blueprint),
         {:ok, config} = SubscribeSelf.get_config(field, blueprint.execution.context, blueprint),
         {_, ordinal_fun} when is_function(ordinal_fun, 1) <- {:ordinal_fun, config[:ordinal]},
         {_, ordinal_compare_fun} when is_function(ordinal_compare_fun, 2) <-
           {:ordinal_compare_fun,
            Keyword.get(config, :ordinal_compare, &default_ordinal_compare/2)} do
      ordinal = ordinal_fun.(blueprint.execution.root_value)

      result =
        blueprint.result
        |> Map.put(:ordinal, ordinal)
        |> Map.put(:ordinal_compare_fun, ordinal_compare_fun)

      {:ok, %{blueprint | result: result}}
    else
      {:ordinal_fun, f} when is_function(f) ->
        IO.write(
          :stderr,
          "Ordinal function must be 1-arity"
        )

        {:ok, blueprint}

      {:ordinal_compare_fun, f} when is_function(f) ->
        IO.write(
          :stderr,
          "Ordinal compare function must be 2-arity"
        )

        {:ok, blueprint}

      _ ->
        {:ok, blueprint}
    end
  end

  defp default_ordinal_compare(nil, new_ordinal), do: {true, new_ordinal}

  defp default_ordinal_compare(old_ordinal, new_ordinal) when old_ordinal < new_ordinal,
    do: {true, new_ordinal}

  defp default_ordinal_compare(old_ordinal, _new_ordinal), do: {false, old_ordinal}
end
