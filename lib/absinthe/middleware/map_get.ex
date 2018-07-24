defmodule Absinthe.Middleware.MapGet do
  @moduledoc """
  This is the default middleware. It assumes the the object it receives is a map
  and uses `Map.get/2` to get the value for this field. If this field is already
  marked as resolved, then this middleware does not touch it.

  If you want to replace this middleware you should use
  `Absinthe.Schema.replace_default/4`
  """

  @behaviour Absinthe.Middleware

  def call(%{state: :unresolved, source: source} = res, key) do
    %{res | state: :resolved, value: Map.get(source, key)}
  end

  def call(res, _key), do: res
end
