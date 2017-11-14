defmodule Absinthe.Middleware.OrdMapGet do
  @moduledoc """
  This is middleware for ordered results.
  """

  @behaviour Absinthe.Middleware

  def call(%{source: source} = res, key) do
    %{res | state: :resolved, value: OrdMap.get(OrdMap.new(source), key)}
  end
end
