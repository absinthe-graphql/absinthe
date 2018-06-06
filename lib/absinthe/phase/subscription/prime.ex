defmodule Absinthe.Phase.Subscription.Prime do
  @moduledoc false

  @spec run(any(), Keyword.t()) :: Phase.result_t()
  def run(blueprint, [prime_result: cr]) do
    {:ok, put_in(blueprint.execution.root_value, cr)}
  end
end
