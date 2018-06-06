defmodule Absinthe.Middleware.Defer do
  @moduledoc false

  # Suspends deferred fields so that they are not immediately processed

  @behaviour Absinthe.Middleware

  def call(%{state: :unresolved} = res, _),
    do: %{res | state: :suspended, acc: Map.put(res.acc, :deferred_res, res)}

  def call(res, _), do: res
end
