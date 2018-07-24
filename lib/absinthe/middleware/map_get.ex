defmodule Absinthe.Middleware.MapGet do
  @moduledoc """
  This is the default middleware.
  """

  @behaviour Absinthe.Middleware

  def call(%{state: :unresolved, source: source} = res, key) do
    %{res | state: :resolved, value: Map.get(source, key)}
  end

  def call(res, _key), do: res
end
