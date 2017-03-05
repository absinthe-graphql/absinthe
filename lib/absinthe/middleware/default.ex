defmodule Absinthe.Middleware.MapGet do
  @moduledoc """
  This is the default middlware.
  """

  @behaviour Absinthe.Middleware

  def call(%{source: source} = res, field_identifier) do
    %{res | state: :resolved, value: Map.get(source, field_identifier)}
  end
end
