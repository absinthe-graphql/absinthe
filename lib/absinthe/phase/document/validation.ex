defmodule Absinthe.Phase.Document.Validation do

  use Absinthe.Phase

  alias __MODULE__

  @type rule_t :: module

  @rules [
    Validation.NoFragmentCycles
  ]

  def run(input, _) do
    case do_run(input) do
      {:error, _} = err ->
        err
      result ->
        {:ok, result}
    end
  end

  defp do_run(input) do
    Enum.reduce_while(@rules, input, fn
      rule, blueprint ->
        case rule.run(blueprint) do
          {:ok, result} ->
            {:cont, result}
          {:error, _} = err ->
            {:halt, err}
        end
    end)
  end

end
