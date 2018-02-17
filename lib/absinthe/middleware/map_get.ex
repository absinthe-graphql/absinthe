defmodule Absinthe.Middleware.MapGet do
  @moduledoc """
  This is the default middleware.
  """

  @behaviour Absinthe.Middleware

  def call(%{source: source} = res, key) do
    %{res | state: :resolved, value: Map.get(source, key)}
  end
end
